class UsageReportingJob < ApplicationJob
  def perform
    # If there's no ID, don't send
    return unless SiteSettings.anonymous_usage_id
    # Get the endpoint
    uri = URI.parse(UsageReport.endpoint)
    # Prepare the report
    data = UsageReport.generate
    # Tell the user what we're doing
    Rails.logger.info("Sending anonymous usage report to #{uri}: #{data}")
    # Send
    headers = {
      "Content-Type": "application/json",
      "User-Agent": "Manyfold::UsageReportingJob"
    }
    Net::HTTP.post(uri, data, headers)
  end
end
