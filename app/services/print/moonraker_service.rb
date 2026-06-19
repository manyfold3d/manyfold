require "faraday"
require "faraday/multipart"

class Print::MoonrakerService
  # i18n-tasks-use t("print_hosts.protocols.moonraker")
  PROTOCOL = "moonraker".freeze

  INPUT_TYPES = [Mime[:gcode]].freeze

  def initialize(print_host:)
    @print_host = print_host
  end

  def ok?
    response = connection.get(info_uri, {}, headers)
    Rails.logger.warn(response.inspect) unless response.success?
    response.success?
  rescue
    false
  end

  def upload(file:, start_print: true)
    raise ArgumentError unless file.mime_type.in? INPUT_TYPES
    raise PrintHost::NotReady unless ok?
    response = connection.post(upload_uri, payload(file: file, start_print: start_print), headers)
    Rails.logger.warn(response.inspect) unless response.success?
    response.success?
  end

  private

  def connection
    Faraday.new do
      it.request :multipart
    end
  end

  def payload(file:, start_print: true)
    {
      print: start_print ? "true" : "false",
      file: Faraday::Multipart::FilePart.new(
        file.attachment.open,
        file.mime_type.to_s,
        file.filename
      )
    }
  end

  def info_uri
    "#{@print_host.endpoint}/server/info"
  end

  def upload_uri
    "#{@print_host.endpoint}/server/files/upload"
  end

  def headers
    {
      "X-Api-Key" => @print_host.credentials
    }.compact_blank
  end
end
