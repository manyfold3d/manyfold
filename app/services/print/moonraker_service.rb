require "faraday"
require "faraday/multipart"

class Print::MoonrakerService
  def initialize(server_root:)
    @server_root = server_root
  end

  def upload(file:, start_print: true)
    raise ArgumentError unless file.mime_type.to_sym == :gcode
    connection.post(uri, payload(file: file, start_print: start_print))
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

  def uri
    "#{@server_root}/server/files/upload"
  end
end
