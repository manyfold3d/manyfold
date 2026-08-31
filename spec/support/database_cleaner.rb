RSpec.configure do |config|
  config.before(:suite) do
    # Allow remote DATABASE_URL in CI/Docker (e.g. postgresql://manyfold@db:5432/manyfold)
    remote = ENV["CI"] == "true" || ENV["DOCKER_TEST"] == "1"
    DatabaseCleaner.allow_remote_database_url = true if remote || ENV["DATABASE_HOST"].present?
    # Use :deletion in Docker/CI to avoid PG deadlocks when Sidekiq holds a connection
    # (truncation needs exclusive locks). INIT-016/SPEC-002: also use deletion for suite
    # clean_with — truncation against port-forwarded/remote PG can hang or drop the session.
    strategy = remote ? :deletion : :truncation
    DatabaseCleaner.clean_with(strategy)
    DatabaseCleaner.strategy = strategy
  end

  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
