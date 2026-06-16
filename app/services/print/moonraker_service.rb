require "faraday"
require "faraday/multipart"

class Print::MoonrakerService
  # i18n-tasks-use t("print_hosts.protocols.moonraker")
  PROTOCOL = "moonraker".freeze

  def initialize(print_host:)
    @print_host = print_host
  end
  end

  def upload(file:, start_print: true)
    raise ArgumentError unless file.mime_type.to_sym == :gcode
    connection.post(upload_uri, payload(file: file, start_print: start_print))
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

  def upload_uri
    "#{@print_host.endpoint}/server/files/upload"
  end
end
