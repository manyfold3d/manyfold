# frozen_string_literal: true

Altcha.setup do |config|
  config.max_number = 500_000
  config.timeout = 5.minutes
  config.hmac_key = ENV.fetch("SECRET_KEY_BASE", SecureRandom.hex(32))
end
