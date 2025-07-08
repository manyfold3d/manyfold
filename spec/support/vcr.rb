require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :faraday
  config.ignore_localhost = true
  config.configure_rspec_metadata!
end

RSpec.configure do |config|
  config.before(:each, :mmf_api_key) do
    allow(SiteSettings).to receive(:myminifactory_api_key).and_return(ENV.fetch("MYMINIFACTORY_API_KEY", "mmf_key_placeholder"))
    VCR.configure { |c| c.filter_sensitive_data("<MYMINIFACTORY_API_KEY>") { SiteSettings.myminifactory_api_key } }
  end

  config.before(:each, :thingiverse_api_key) do |example|
    allow(SiteSettings).to receive(:thingiverse_api_key).and_return(ENV.fetch("THINGIVERSE_API_KEY", "thingiverse_key_placeholder"))
    VCR.configure { |c| c.filter_sensitive_data("<THINGIVERSE_API_KEY>") { SiteSettings.thingiverse_api_key } }
  end
end
