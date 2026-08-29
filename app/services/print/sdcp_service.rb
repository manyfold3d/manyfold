# frozen_string_literal: true

require "digest"
require "json"
require "net/http"
require "securerandom"
require "socket"
require "uri"
require "websocket"

module Print
  # SDCP 3.0 client for UniFormation / ChituManager-family printers (GK3 Pro).
  # Control: WebSocket `:3030/websocket`. Upload: HTTP multipart `:3030/uploadFile/upload`.
  # Video: Cmd 386 → RTSP URL (multiplex via go2rtc — do not open unbounded RTSP clients).
  class SdcpService
    PROTOCOL = "sdcp"
    INPUT_TYPES = [Mime[:chitubox], Mime[:jxs]].freeze
    DISCOVER_PAYLOAD = "M99999"
    DEFAULT_DISCOVER_PORT = 3000
    DEFAULT_CONTROL_PORT = 3030
    CHUNK_SIZE = 1 * 1024 * 1024 # SDCP HTTP upload packet size

    # Binding caps from INIT-009 ADR D-1 (REQ-005). UI polls must be strictly shorter than control.
    SDCP_UI_WS_TIMEOUT = 3
    SDCP_CONTROL_WS_TIMEOUT = 10

    # Socket.tcp(connect_timeout:) raises Errno::ETIMEDOUT (not Timeout::Error). Controllers
    # that omit it turn a soft unreachable printer into an unrescued 500 → UI "offline".
    TRANSPORT_ERRORS = [
      SocketError,
      Errno::ECONNREFUSED,
      Errno::ETIMEDOUT,
      Errno::EHOSTUNREACH,
      Errno::ENETUNREACH,
      Timeout::Error
    ].freeze

    class Error < StandardError; end

    class AckError < Error
      attr_reader :cmd, :ack, :payload

      def initialize(cmd:, ack:, payload: nil)
        @cmd = cmd
        @ack = ack
        @payload = payload
        super("SDCP Cmd #{cmd} Ack=#{ack}")
      end
    end

    class UnsupportedFileType < Error; end

    def initialize(print_host:, session: nil)
      @print_host = print_host
      @injected_session = session
    end

    def ok?
      status.fetch("Ack", 1).zero?
    rescue Error, *TRANSPORT_ERRORS
      false
    end

    # UI status poll — short WS budget (INIT-009/SPEC-002).
    def status
      request_cmd(0, timeout: SDCP_UI_WS_TIMEOUT)
    end

    def attributes
      # Cmd 1 Ack comes on sdcp/response; attributes body often on sdcp/attributes.
      request_cmd(1, collect: :attributes)
    end

    def video_url(enable: true)
      data = request_cmd(386, data: {"Enable" => enable ? 1 : 0})
      url = data["VideoUrl"].to_s
      return url if url.blank? || !enable

      normalize_video_url(url)
    end

    def start_print(filename:, start_layer: 0)
      request_cmd(128, data: {"Filename" => sanitize_remote_filename(filename), "StartLayer" => start_layer})
    end

    def pause_print
      request_cmd(129)
    end

    def stop_print
      request_cmd(130)
    end

    def continue_print
      request_cmd(131)
    end

    # Cmd 258 — list files under Url (default /local).
    def list_files(url: "/local")
      url = sanitize_storage_url(url)
      payload = request_cmd(258, data: {"Url" => url})
      Array(payload["FileList"]).map { |entry| normalize_file_entry(entry) }
    end

    # Cmd 259 — batch delete. Paths must be absolute SDCP paths under /local.
    def delete_files(file_list: [], folder_list: [])
      files = sanitize_storage_paths(file_list)
      folders = sanitize_storage_paths(folder_list)
      raise Error, "nothing_to_delete" if files.blank? && folders.blank?

      request_cmd(259, data: {
        "FileList" => files,
        "FolderList" => folders
      })
    end

    # Free bytes from host cache, refreshed file-list totals, or nil when unknown.
    def storage_free_bytes
      used = print_host.storage_bytes_used
      total = print_host.storage_bytes_total
      return total.to_i - used.to_i if !used.nil? && !total.nil?

      nil
    end

    # Refresh storage counters from a file-list response root entry when present.
    def refresh_storage_from_list!(url: "/local")
      url = sanitize_storage_url(url)
      payload = request_cmd(258, data: {"Url" => url})
      entries = Array(payload["FileList"])
      sample = entries.find { |e| e.is_a?(Hash) && e.key?("totalSize") } || payload
      used = sample["usedSize"] || sample["UsedSize"]
      total = sample["totalSize"] || sample["TotalSize"]
      return print_host if used.nil? || total.nil?

      print_host.update!(
        storage_bytes_used: used.to_i,
        storage_bytes_total: total.to_i
      )
      print_host
    end

    # Pull FEP (ReleaseFilm) / LCD (PrintScreen hours) from status/attributes when available.
    def refresh_maintenance_counters!
      status_body = status
      status_hash = status_body["Status"] if status_body.is_a?(Hash)
      status_hash ||= status_body if status_body.is_a?(Hash)

      fep = dig_num(status_hash, "ReleaseFilm")
      lcd_seconds = dig_num(status_hash, "PrintScreen")

      if fep.nil? || lcd_seconds.nil?
        attrs = attributes
        fep ||= dig_num(attrs, "ReleaseFilm") || dig_num(attrs, "ReleaseFilmMax")
        lcd_seconds ||= dig_num(attrs, "PrintScreen")
      end

      updates = {}
      updates[:fep_cycles] = fep.to_i unless fep.nil?
      unless lcd_seconds.nil?
        # Avoid BigDecimal#/ under YJIT (known panic on some 3.4 builds); use Float.
        updates[:lcd_hours] = (lcd_seconds.to_f / 3600.0).round(4)
      end
      print_host.update!(updates) if updates.any?
      print_host
    end

    # Normalized monitor DTO (REQ-007 shaped) from Cmd 0 status payload.
    # When raw is omitted, uses the UI status budget (INIT-009/SPEC-002).
    def normalized_status(raw = nil)
      raw ||= status
      body = raw.is_a?(Hash) ? (raw["Status"] || raw) : {}
      info = body["PrintInfo"].is_a?(Hash) ? body["PrintInfo"] : {}
      current_ticks = info["CurrentTicks"].to_i
      total_ticks = info["TotalTicks"].to_i
      eta_seconds = if total_ticks.positive? && total_ticks >= current_ticks
        ((total_ticks - current_ticks) / 1000.0).round
      end

      {
        machine_status: Array(body["CurrentStatus"]),
        print_status: info["Status"],
        current_layer: info["CurrentLayer"],
        total_layers: info["TotalLayer"],
        eta_seconds: eta_seconds,
        filename: info["Filename"],
        temp_uv_c: body["TempOfUVLED"],
        temp_box_c: body["TempOfBox"],
        temp_box_target_c: body["TempTargetBox"],
        fep_cycles: body["ReleaseFilm"],
        lcd_seconds: body["PrintScreen"],
        task_id: info["TaskId"],
        error_number: info["ErrorNumber"],
        raw: raw
      }
    end

    # Uploads a sliced CTB/JXS file in 1MB chunks, then optionally starts print.
    # When free space is known and insufficient, raises before uploading (REQ-005).
    def upload(io:, filename:, content_type: nil, start: false, start_layer: 0)
      filename = sanitize_remote_filename(filename)
      assert_supported_filename!(filename)

      bytes = io.respond_to?(:read) ? io.read : io.to_s
      raise Error, "empty upload" if bytes.blank?

      free = storage_free_bytes
      if !free.nil? && bytes.bytesize > free
        raise Error, "insufficient on-printer storage (need #{bytes.bytesize}, free #{free})"
      end

      md5 = Digest::MD5.hexdigest(bytes)
      uuid = SecureRandom.uuid
      total = bytes.bytesize
      offset = 0

      while offset < total
        chunk = bytes.byteslice(offset, CHUNK_SIZE)
        post_upload_chunk(
          chunk: chunk,
          filename: filename,
          md5: md5,
          uuid: uuid,
          offset: offset,
          total_size: total,
          content_type: content_type
        )
        offset += chunk.bytesize
      end

      start_print(filename: filename, start_layer: start_layer) if start
      {filename: filename, md5: md5, bytes: total}
    end

    # UDP discover (unicast to host or broadcast). Returns parsed attribute hash or nil.
    def self.discover(host: "255.255.255.255", port: DEFAULT_DISCOVER_PORT, timeout: 2.0)
      discover_candidates(hosts: [host], port: port, timeout: timeout).first
    end

    # UDP M99999 discover. Returns candidate hashes only — does NOT persist PrintHost (REQ-003).
    # Targets and reported MainboardIP must pass EndpointAllowlist (SSRF — INIT-008/SPEC-008).
    def self.discover_candidates(hosts: ["255.255.255.255"], port: DEFAULT_DISCOVER_PORT, timeout: 2.0)
      safe_hosts = EndpointAllowlist.filter_discover_targets(hosts)
      raise Error, "no allowlisted discover targets" if safe_hosts.empty?

      timeout = timeout.to_f.clamp(0.1, 5.0)
      socket = UDPSocket.new
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
      safe_hosts.each { |host| socket.send(DISCOVER_PAYLOAD, 0, host, port) }

      candidates = []
      seen = {}
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
      loop do
        remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
        break if remaining <= 0

        readable, = IO.select([socket], nil, nil, remaining)
        break unless readable

        data, addr = socket.recvfrom(65_535)
        parsed = parse_discover_payload(data)
        next unless parsed

        candidate = normalize_discover_candidate(parsed, addr)
        next unless discover_candidate_allowed?(candidate)

        key = candidate[:mainboard_id].presence || candidate[:endpoint]
        next if key.blank? || seen[key]

        seen[key] = true
        candidates << candidate
      end
      candidates
    ensure
      socket&.close
    end

    def self.discover_candidate_allowed?(candidate)
      endpoint = candidate[:endpoint].to_s
      return false if endpoint.blank?

      host = URI.parse(endpoint).host
      EndpointAllowlist.allowed?(host)
    rescue URI::InvalidURIError
      false
    end
    private_class_method :discover_candidate_allowed?

    def self.parse_discover_payload(data)
      text = data.to_s
      json_start = text.index("{")
      return nil unless json_start

      JSON.parse(text[json_start..])
    rescue JSON::ParserError
      nil
    end

    def self.normalize_discover_candidate(parsed, addr = nil)
      # GK3 / UniFormation nest identity under Data; older samples use top-level keys.
      data = parsed.is_a?(Hash) ? (parsed["Data"].is_a?(Hash) ? parsed["Data"] : parsed) : {}
      top = parsed.is_a?(Hash) ? parsed : {}
      pick = ->(key) { data[key].presence || top[key].presence }

      ip = pick.call("MainboardIP") || addr&.[](3)
      {
        brand: pick.call("BrandName"),
        machine_model: pick.call("MachineName") || pick.call("Name"),
        mainboard_id: pick.call("MainboardID"),
        firmware: pick.call("FirmwareVersion"),
        protocol_version: pick.call("ProtocolVersion"),
        endpoint: ip.present? ? "http://#{ip}:#{DEFAULT_CONTROL_PORT}" : nil,
        raw: parsed
      }
    end

    private

    attr_reader :print_host

    def request_cmd(cmd, data: {}, collect: :response, timeout: SDCP_CONTROL_WS_TIMEOUT)
      assert_endpoint_allowed!
      payload = session_for(timeout).call(cmd: cmd, data: data, collect: collect)
      ack = payload.is_a?(Hash) ? payload["Ack"] : nil
      if ack && ack != 0
        raise AckError.new(cmd: cmd, ack: ack, payload: payload)
      end
      payload
    end

    # Injected session wins (specs). Otherwise cache one WebsocketSession per timeout budget.
    def session_for(timeout)
      return @injected_session if @injected_session

      @sessions ||= {}
      @sessions[timeout] ||= WebsocketSession.new(
        url: websocket_url,
        mainboard_id: print_host.mainboard_id.to_s,
        timeout: timeout
      )
    end

    # URI#port returns 80/443 when the URL omits a port — never use those for SDCP.
    def control_port
      uri = URI.parse(print_host.endpoint.to_s)
      port = uri.port
      return DEFAULT_CONTROL_PORT if port.nil? || port == uri.default_port

      port
    end

    def websocket_url
      assert_endpoint_allowed!
      uri = URI.parse(print_host.endpoint)
      "ws://#{uri.host}:#{control_port}/websocket"
    end

    def upload_url
      assert_endpoint_allowed!
      uri = URI.parse(print_host.endpoint)
      "#{uri.scheme}://#{uri.host}:#{control_port}/uploadFile/upload"
    end

    # Re-resolve at connect time to close DNS-rebinding TOCTOU after model validation.
    def assert_endpoint_allowed!
      uri = URI.parse(print_host.endpoint.to_s)
      unless EndpointAllowlist.allowed?(uri.host)
        raise Error, "PrintHost endpoint not on private LAN allowlist"
      end
    rescue URI::InvalidURIError
      raise Error, "PrintHost endpoint invalid"
    end

    def assert_supported_filename!(filename)
      ext = File.extname(filename.to_s).delete(".").downcase
      mime = Mime::Type.lookup_by_extension(ext)
      return if INPUT_TYPES.include?(mime)

      raise UnsupportedFileType, "SDCP accepts CTB/JXS only (got #{filename.inspect})"
    end

    def sanitize_remote_filename(filename)
      base = File.basename(filename.to_s)
      raise Error, "invalid upload filename" if base.blank? || base == "." || base == ".."

      base
    end

    def sanitize_storage_url(url)
      path = url.to_s
      path = "/local" if path.blank?
      unless path.start_with?("/local")
        raise Error, "storage url must be under /local"
      end
      if path.include?("..")
        raise Error, "storage url path traversal rejected"
      end

      path
    end

    def sanitize_storage_paths(paths)
      Array(paths).map(&:to_s).reject(&:blank?).map { |p|
        raise Error, "storage path must be under /local" unless p.start_with?("/local")
        raise Error, "storage path traversal rejected" if p.include?("..")

        p
      }
    end

    def normalize_file_entry(entry)
      return entry unless entry.is_a?(Hash)

      {
        name: entry["name"] || entry["Name"],
        used_size: entry["usedSize"] || entry["UsedSize"],
        total_size: entry["totalSize"] || entry["TotalSize"],
        storage_type: entry["storageType"] || entry["StorageType"],
        type: entry["type"] || entry["Type"],
        raw: entry
      }
    end

    def dig_num(hash, key)
      return nil unless hash.is_a?(Hash)
      val = hash[key]
      return nil if val.nil?

      val
    end

    def normalize_video_url(url)
      uri = URI.parse(url)
      if uri.host.blank?
        host = URI.parse(print_host.endpoint).host
        uri.host = host
      end
      unless EndpointAllowlist.allowed?(uri.host)
        raise Error, "VideoUrl host not on private LAN allowlist"
      end
      uri.to_s
    rescue URI::InvalidURIError
      raise Error, "VideoUrl invalid"
    end

    def post_upload_chunk(chunk:, filename:, md5:, uuid:, offset:, total_size:, content_type:)
      uri = URI.parse(upload_url)
      boundary = "----ManyfoldSdcp#{SecureRandom.hex(8)}"
      body = multipart_body(
        boundary: boundary,
        filename: filename,
        chunk: chunk,
        md5: md5,
        uuid: uuid,
        offset: offset,
        total_size: total_size,
        content_type: content_type || "application/octet-stream"
      )

      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 10
      http.read_timeout = 120
      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
      request.body = body
      response = http.request(request)
      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "upload HTTP #{response.code}: #{response.body.to_s.truncate(200)}"
      end

      parsed = JSON.parse(response.body)
      unless parsed["success"] == true || parsed["code"] == "000000"
        raise Error, "upload rejected: #{response.body.to_s.truncate(200)}"
      end
      parsed
    rescue JSON::ParserError
      raise Error, "upload non-JSON response: #{response.body.to_s.truncate(200)}"
    end

    def multipart_body(boundary:, filename:, chunk:, md5:, uuid:, offset:, total_size:, content_type:)
      lines = []
      {
        "S-File-MD5" => md5,
        "Check" => "1",
        "Offset" => offset.to_s,
        "Uuid" => uuid,
        "TotalSize" => total_size.to_s
      }.each do |name, value|
        lines << "--#{boundary}\r\n"
        lines << "Content-Disposition: form-data; name=\"#{name}\"\r\n\r\n"
        lines << "#{value}\r\n"
      end
      lines << "--#{boundary}\r\n"
      lines << "Content-Disposition: form-data; name=\"File\"; filename=\"#{filename}\"\r\n"
      lines << "Content-Type: #{content_type}\r\n\r\n"
      binary = (+"").force_encoding(Encoding::BINARY)
      lines.each { |part| binary << part.b }
      binary << chunk.b
      binary << "\r\n--#{boundary}--\r\n".b
      binary
    end

    # Minimal SDCP WebSocket session using the `websocket` gem (already in lockfile).
    class WebsocketSession
      def initialize(url:, mainboard_id:, timeout: SdcpService::SDCP_CONTROL_WS_TIMEOUT)
        @url = url
        @mainboard_id = mainboard_id
        @timeout = timeout
      end

      def call(cmd:, data: {}, collect: :response)
        uri = URI.parse(@url)
        Socket.tcp(uri.host, uri.port, connect_timeout: @timeout) do |socket|
          socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
          handshake = ::WebSocket::Handshake::Client.new(url: @url)
          socket.write(handshake.to_s)
          complete_handshake!(socket, handshake)

          request_id = SecureRandom.uuid
          envelope = {
            "Id" => SecureRandom.uuid,
            "Data" => {
              "Cmd" => cmd,
              "Data" => data,
              "RequestID" => request_id,
              "MainboardID" => @mainboard_id,
              "TimeStamp" => Time.now.to_i,
              "From" => 0
            }
          }
          out = ::WebSocket::Frame::Outgoing::Client.new(
            data: JSON.generate(envelope),
            type: :text,
            version: handshake.version
          )
          socket.write(out.to_s)

          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + @timeout
          incoming = ::WebSocket::Frame::Incoming::Client.new(version: handshake.version)
          attributes_payload = nil

          loop do
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise Error, "SDCP WS timeout waiting for Cmd #{cmd}" if remaining <= 0

            ready, = IO.select([socket], nil, nil, remaining)
            raise Error, "SDCP WS timeout waiting for Cmd #{cmd}" unless ready

            chunk = socket.read_nonblock(65_535, exception: false)
            next if chunk == :wait_readable
            raise Error, "SDCP WS closed" if chunk.nil? || chunk.empty?

            incoming << chunk
            while (frame = incoming.next)
              next unless frame.type == :text

              message = JSON.parse(frame.data)
              topic = message["Topic"].to_s
              if topic.include?("attributes") && message["Attributes"]
                attributes_payload = message["Attributes"]
                return attributes_payload if collect == :attributes
              end

              data_body = message["Data"]
              next unless data_body.is_a?(Hash)
              next unless data_body["Cmd"] == cmd

              # Match RequestID when present; some firmware echoes differently.
              rid = data_body["RequestID"]
              next if rid.present? && rid != request_id

              payload = data_body["Data"] || {}
              if collect == :attributes
                return attributes_payload if attributes_payload
                # Keep waiting for attributes topic after Ack.
                next
              end

              return payload
            end
          end
        end
      end

      private

      def complete_handshake!(socket, handshake)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + @timeout
        until handshake.finished?
          remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          raise Error, "SDCP WS handshake timeout" if remaining <= 0

          ready, = IO.select([socket], nil, nil, remaining)
          raise Error, "SDCP WS handshake timeout" unless ready

          chunk = socket.read_nonblock(65_535, exception: false)
          next if chunk == :wait_readable
          raise Error, "SDCP WS handshake closed" if chunk.nil? || chunk.empty?

          handshake << chunk
        end
        raise Error, "SDCP WS handshake failed" unless handshake.valid?
      end
    end
  end
end
