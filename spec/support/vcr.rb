require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :faraday
  config.ignore_localhost = true
  config.configure_rspec_metadata!
  config.filter_sensitive_data("<MYMINIFACTORY_API_KEY>") { ENV.fetch("MYMINIFACTORY_API_KEY", "abcd1234") }
end

RSpec.configure do |config|
  config.around(:each, :mmf_api_key) do |example|
    ClimateControl.modify MYMINIFACTORY_API_KEY: "abcd1234" do
      example.run
    end
  end
end
