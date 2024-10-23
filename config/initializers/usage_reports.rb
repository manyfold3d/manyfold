require "usage_report"

Rails.application.config.after_initialize do
  # Make sure the schedule is loaded correctly
  UsageReport.set_schedule!
rescue RedisClient::CannotConnectError
end
