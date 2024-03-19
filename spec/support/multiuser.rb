RSpec.configure do |config|
  config.before(:each, :multiuser) do
    allow(Flipper).to receive(:enabled?).and_call_original
    allow(Flipper).to receive(:enabled?).with(:multiuser).and_return(true)
  end
end
