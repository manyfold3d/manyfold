module PublicUrl
  def self.port
    ENV.fetch("PUBLIC_PORT", ENV.fetch("RAILS_PORT", "3214"))
  end

  def self.nonstandard_port
    ["80", "443"].include?(port) ? nil : port
  end

  def self.hostname
    ENV.fetch("PUBLIC_HOSTNAME", "localhost")
  end
end
