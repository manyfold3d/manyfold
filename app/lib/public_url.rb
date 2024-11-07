module PublicUrl
  def self.port
    # PUBLIC_PORT overrides everything
    return ENV.fetch("PUBLIC_PORT") if ENV.key?("PUBLIC_PORT")
    # If hostname is set, assume a standard port
    if ENV.key?("PUBLIC_HOSTNAME")
      https = ENV.fetch("HTTPS_ONLY", nil) === "enabled"
      return https ? "443" : "80"
    end
    # Fall back to RAILS_PORT or default
    ENV.fetch("RAILS_PORT", "3214")
  end

  def self.nonstandard_port
    ["80", "443"].include?(port) ? nil : port
  end

  def self.hostname
    ENV.fetch("PUBLIC_HOSTNAME", "localhost")
  end
end
