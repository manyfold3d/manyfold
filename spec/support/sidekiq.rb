RSpec.configure do |config|
  config.before do
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Uniqueness.test_mode!
    allow(Sidekiq::Queue).to receive(:new).with("scan").and_return([])
  end
end
