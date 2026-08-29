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
    CHUNK_SIZE = 1 * 1024 * 1024 # SDCP HTTP upload packet size

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
      @session = session
    end

    def ok?
      status.fetch("Ack", 1).zero?
    rescue Error, SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT, Timeout::Error
      false
    end

    def status
      request_cmd(0)
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
      request_cmd(128, data: {"Filename" => filename, "StartLayer" => start_layer})
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

    # Uploads a sliced CTB/JXS file in 1MB chunks, then optionally starts print.
    def upload(io:, filename:, content_type: nil, start: false, start_layer: 0)
      assert_supported_filename!(filename)

      bytes = io.respond_to?(:read) ? io.read : io.to_s
      raise Error, "empty upload" if bytes.blank?

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
      socket = UDPSocket.new
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
      socket.send(DISCOVER_PAYLOAD, 0, host, port)
      readable, = IO.select([socket], nil, nil, timeout)
      return nil unless readable

      data, = socket.recvfrom(65_535)
      parse_discover_payload(data)
    ensure
      socket&.close
    end

    def self.parse_discover_payload(data)
      text = data.to_s
      json_start = text.index("{")
      return nil unless json_start

      JSON.parse(text[json_start..])
    rescue JSON::ParserError
      nil
    end

    private

    attr_reader :print_host

    def request_cmd(cmd, data: {}, collect: :response)
      payload = session.call(cmd: cmd, data: data, collect: collect)
      ack = payload.is_a?(Hash) ? payload["Ack"] : nil
      if ack && ack != 0
        raise AckError.new(cmd: cmd, ack: ack, payload: payload)
      end
      payload
    end

    def session
      @session ||= WebsocketSession.new(
        url: websocket_url,
        mainboard_id: print_host.mainboard_id.to_s,
        timeout: 10
      )
    end

    def websocket_url
      uri = URI.parse(print_host.endpoint)
      "ws://#{uri.host}:#{uri.port || 3030}/websocket"
    end

    def upload_url
      uri = URI.parse(print_host.endpoint)
      "#{uri.scheme}://#{uri.host}:#{uri.port || 3030}/uploadFile/upload"
    end

    def assert_supported_filename!(filename)
      ext = File.extname(filename.to_s).delete(".").downcase
      mime = Mime::Type.lookup_by_extension(ext)
      return if INPUT_TYPES.include?(mime)

      raise UnsupportedFileType, "SDCP accepts CTB/JXS only (got #{filename.inspect})"
    end

    def normalize_video_url(url)
      uri = URI.parse(url)
      if uri.host.blank?
        host = URI.parse(print_host.endpoint).host
        uri.host = host
      end
      uri.to_s
    rescue URI::InvalidURIError
      url
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
      def initialize(url:, mainboard_id:, timeout: 10)
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
