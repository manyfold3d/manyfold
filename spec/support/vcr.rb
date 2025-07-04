require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :faraday
  config.ignore_localhost = true
  config.configure_rspec_metadata!
  config.filter_sensitive_data("<MYMINIFACTORY_API_KEY>") { ENV["MYMINIFACTORY_API_KEY"] }
end
