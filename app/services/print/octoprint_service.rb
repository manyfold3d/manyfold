require "faraday"
require "faraday/multipart"

class Print::OctoprintService
  # i18n-tasks-use t("print_hosts.protocols.octoprint")
  PROTOCOL = "octoprint".freeze

  INPUT_TYPES = [Mime[:gcode]].freeze

  def initialize(print_host:)
    @print_host = print_host
  end

  def ok?
    response = connection.get(info_uri, {}, headers)
    response.success?
  rescue => ex
    Rails.logger.warn(ex.message)
    false
  end

  def upload(file:, start_print: true)
    raise ArgumentError unless file.mime_type.to_sym == :gcode
    connection.post(upload_uri, payload(file: file, start_print: start_print), headers)
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
    "#{@print_host.endpoint}/api/server"
  end

  def upload_uri
    "#{@print_host.endpoint}/api/files/local"
  end

  def headers
    {
      "X-Api-Key" => @print_host.credentials
    }.compact_blank
  end
end
