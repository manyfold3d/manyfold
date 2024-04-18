RSpec.configure do |config|
  config.before do
    ActiveJob::Base.queue_adapter = :test
    allow(Sidekiq::Queue).to receive(:new).with("scan").and_return([])
  end
end
