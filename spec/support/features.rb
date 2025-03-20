RSpec.configure do |config|
  config.before(:each, :multiuser) do
    allow(SiteSettings).to receive(:multiuser_enabled?).and_return(true)
  end

  config.before(:each, :singleuser) do
    allow(SiteSettings).to receive(:multiuser_enabled?).and_return(false)
  end

  config.before(:each, :demo_mode) do
    allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(true)
  end
end
