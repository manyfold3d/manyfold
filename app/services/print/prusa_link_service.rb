require "faraday"
require "faraday/multipart"

module Print
  class PrusaLinkService
    # i18n-tasks-use t("print_hosts.protocols.prusalink")
    PROTOCOL = "prusalink".freeze

    INPUT_TYPES = [Mime[:gcode], Mime[:sl1]].freeze

    def initialize(print_host:)
      @print_host = print_host
    end

    def ok?
      response = connection.get(info_uri, {}, headers)
      Rails.logger.warn(response.inspect) unless response.success?
      response.success?
    rescue => ex
      Rails.logger.warn(ex.message)
      false
    end

    def upload(file:, start_print: true)
      raise ArgumentError unless file.mime_type.in? INPUT_TYPES
      raise PrintHost::NotReady unless ok?
      response = v1_upload(file: file)
      Rails.logger.warn(response.inspect) unless response.success?
      response.success?
    end

    private

    def connection
      Faraday.new do
        it.request :multipart
      end
    end

    def info_uri
      "#{@print_host.endpoint}/api/printer"
    end

    def v1_upload(file:)
      connection.post(
        "#{@print_host.endpoint}/api/files/local",
        v1_payload(file: file),
        headers
      )
    end

    def v1_payload(file:, start_print: true)
      {
        select: start_print ? "true" : "false",
        file: Faraday::Multipart::FilePart.new(
          file.attachment.open,
          file.mime_type.to_s,
          file.filename
        )
      }
    end

    def headers
      {
        "X-Api-Key" => @print_host.credentials
      }.compact_blank
    end
  end
end
