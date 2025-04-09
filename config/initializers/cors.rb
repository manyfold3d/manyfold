Rails.application.config.middleware.insert_before 0, Rack::Cors do
  # Allow cross-origin requests for API content types
  allow do
    origins "*"
    resource "*",
      headers: [:any],
      methods: [:get, :options, :head],
      if: ->(env) { env["HTTP_ACCEPT"].split(", ").include? Mime[:json_ld].to_s }
  end
end
