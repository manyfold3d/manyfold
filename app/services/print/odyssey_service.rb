require "faraday"
require "faraday/multipart"

class Print::OdysseyService
  # i18n-tasks-use t("print_hosts.protocols.odyssey")
  PROTOCOL = "odyssey".freeze

  INPUT_TYPES = [Mime[:sl1]].freeze

  def initialize(print_host:)
    @print_host = print_host
  end

  def ok?
    response = connection.get(info_uri, {}, {})
    Rails.logger.warn(response.inspect) unless response.success?
    response.success?
  rescue => ex
    Rails.logger.warn(ex.message)
    false
  end

  def upload(file:, start_print: true)
    raise ArgumentError unless file.mime_type.in? INPUT_TYPES
    raise PrintHost::NotReady unless ok?
    response = connection.post(
      upload_uri,
      payload(file: file)
    )
    Rails.logger.warn(response.inspect) unless response.success?
    uploaded = response.success?
    print(file: file) if start_print
    uploaded
  end

  def print(file:)
    response = Faraday.new.post("#{@print_host.endpoint}/print/start?filename=#{CGI.escapeURIComponent(file.filename)}")
    Rails.logger.warn(response.inspect) unless response.success?
  end

  private

  def connection
    Faraday.new do
      it.request :multipart
    end
  end

  def payload(file:)
    {
      file: Faraday::Multipart::FilePart.new(
        file.attachment.open,
        file.mime_type.to_s,
        file.filename
      )
    }
  end

  def upload_uri
    "#{@print_host.endpoint}/files"
  end

  def info_uri
    "#{@print_host.endpoint}/status"
  end
end
