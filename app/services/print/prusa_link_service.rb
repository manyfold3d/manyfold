require "faraday"
require "faraday/multipart"

module Print
  class PrusaLinkService
    # i18n-tasks-use t("print_hosts.protocols.prusalink")
    PROTOCOL = "prusalink".freeze

    INPUT_TYPES = [Mime[:gcode], Mime[:sl1]].freeze

    DEFAULT_STORAGE = "local".freeze

    def initialize(print_host:)
      @print_host = print_host
    end

    # Reachability check. GET /api/version answers on both the legacy
    # firmware and the newer v1 firmware, the same call doubles as the
    # version-detection probe which is why ok? is built on it.
    def ok?
      version_info.present?
    end

    def upload(file:, start_print: true)
      raise ArgumentError unless file.mime_type.in? INPUT_TYPES
      raise PrintHost::NotReady unless ok?

      response =
        if upload_by_put?
          v1_upload(file: file, start_print: start_print)
        else
          legacy_upload(file: file, start_print: start_print)
        end

      Rails.logger.warn(response.inspect) unless response.success?
      response.success?
    end

    private

    # Memoized so ok? and the upload branch share a single GET /api/version and don't hit the printer twice
    def version_info
      return @version_info if defined?(@version_info)

      @version_info = fetch_version_info
    end

    def fetch_version_info
      response = connection.get(version_uri, {}, headers)

      unless response.success?
        Rails.logger.warn(response.inspect)
        return nil
      end

      JSON.parse(response.body)
    rescue => ex
      Rails.logger.warn(ex.message)
      nil
    end

    def upload_by_put?
      version_info&.dig("capabilities", "upload-by-put") == true
    end

    # Modern path: PUT the raw file bytes to /api/v1/files/{storage}{path}
    # Body is application/octet-stream(not multipart), and print-after-upload
    # is carried by a header using RFC 8941 boolean values("?1"/"?0")
    def v1_upload(file:, start_print: true)
      connection.put(
        v1_upload_uri(file.filename),
        file.attachment.download,
        headers.merge(
          "Content-Type" => "application/octet-stream",
          "Print-After-Upload" => start_print ? "?1" : "?0"
        )
      )
    end

    # Legacy path: OctoPrint-style multipart POST to /api/files/{storage}
    def legacy_upload(file:, start_print: true)
      multipart_connection.post(
        legacy_upload_uri,
        legacy_payload(file: file, start_print: start_print),
        headers
      )
    end

    def legacy_payload(file:, start_print: true)
      {
        select: start_print ? "true" : "false",
        file: Faraday::Multipart::FilePart.new(
          file.attachment.open,
          file.mime_type.to_s,
          file.filename
        )
      }
    end

    # Plain connection for the JSON GET and the raw v1 PUT
    def connection
      Faraday.new
    end

    # Multipart middleware is only needed for legacy support
    def multipart_connection
      Faraday.new do |conn|
        conn.request :multipart
      end
    end

    def version_uri
      "#{@print_host.endpoint}/api/version"
    end

    def v1_upload_uri(filename)
      encoded = ERB::Util.url_encode(filename)
      "#{@print_host.endpoint}/api/v1/files/#{DEFAULT_STORAGE}/#{encoded}"
    end

    def legacy_upload_uri
      "#{@print_host.endpoint}/api/files/#{DEFAULT_STORAGE}"
    end

    def headers
      {
        "X-Api-Key" => @print_host.credentials
      }.compact_blank
    end
  end
end
