module UsageReport
  def self.endpoint
    ENV.fetch("USAGE_TRACKING_URL", "https://tracking.manyfold.app")
  end

  def self.generate
    Jbuilder.encode do |report|
      report.id SiteSettings.anonymous_usage_id
      report.version do |version|
        version.app ENV.fetch("APP_VERSION", Rails.application.config.app_version)
        version.sha ENV.fetch("GIT_SHA", Rails.application.config.git_sha)
      end
    end
  end

  def self.enable!
    SiteSettings.anonymous_usage_id ||= SecureRandom.uuid
    Sidekiq.set_schedule("usage", {every: "1d", class: "UsageReportingJob"})
  end

  def self.disable!
    SiteSettings.anonymous_usage_id = nil
    Sidekiq.remove_schedule("usage")
  end
end
