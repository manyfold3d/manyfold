Amiko.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Logstash.new if Amiko.env.production?
end
