require "faraday"
require "faraday/multipart"

class Print::MoonrakerService
  def initialize(server_root:)
    @server_root = server_root
  end

  def upload(file:, print: true)
    payload = {}
    conn = Faraday.new do |builder|
      builder.request :multipart
      payload[:print] = print ? "true" : "false"
      payload[:file] = Faraday::Multipart::FilePart.new(
        file.attachment.open,
        file.mime_type.to_s,
        file.filename
      )
    end
    conn.post(uri, payload)
  end

  def uri
    "#{@server_root}/server/files/upload"
  end
end
