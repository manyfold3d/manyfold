require "faraday"

module Print
  class DuetService
    # i18n-tasks-use t("print_hosts.protocols.duet")
    PROTOCOL = "duet".freeze

    INPUT_TYPES = [Mime[:gcode]].freeze

    GCODE_DIR = "0:/gcodes".freeze

    DEFAULT_PASSWORD = "reprap".freeze

    def initialize(print_host:)
      @print_host = print_host
    end

    def ok?
      with_session { true }
    rescue => ex
      Rails.logger.warn(ex.message)
      false
    end

    def upload(file:, start_print: true)
      raise ArgumentError unless file.mime_type.in? INPUT_TYPES

      with_session do |session_key|
        upload_response = put_file(file: file, session_key: session_key)
        return false unless upload_response.success?

        if start_print
          return start_print!(filename: file.filename, session_key: session_key).success?
        end

        true
      end
    end

    private

    def with_session
      session_key = connect
      raise PrintHost::NotReady if session_key.nil?

      begin
        yield session_key
      ensure
        disconnect(session_key)
      end
    end

    def connect
      response = connection.get(
        "#{@print_host.endpoint}/machine/connect",
        {password: password}
      )

      unless response.success?
        Rails.logger.warn(response.inspect)
        return nil
      end

      JSON.parse(response.body)["sessionKey"]
    rescue => ex
      Rails.logger.warn(ex.message)
      nil
    end

    def disconnect(session_key)
      connection.get(
        "#{@print_host.endpoint}/machine/disconnect",
        {},
        session_headers(session_key)
      )
    rescue => ex
      Rails.logger.warn(ex.message)
    end

    def put_file(file:, session_key:)
      connection.put(
        upload_uri(file.filename),
        file.attachment.download,
        session_headers(session_key).merge("Content-Type" => "application/octet-stream")
      )
    end

    def start_print!(filename:, session_key:)
      connection.get(
        "#{@print_host.endpoint}/machine/code",
        {},
        session_headers(session_key)
      ) do |req|
        req.body = %(M32 "#{GCODE_DIR}/#{filename}")
      end
    end

    def connection
      Faraday.new
    end

    def upload_uri(filename)
      "#{@print_host.endpoint}/machine/file/#{GCODE_DIR}/#{ERB::Util.url_encode(filename)}"
    end

    def password
      @print_host.credentials.presence || DEFAULT_PASSWORD
    end

    def session_headers(session_key)
      {"X-Session-Key" => session_key}.compact_blank
    end
  end
end
