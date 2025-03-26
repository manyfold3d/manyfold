class ReportHandler
  def self.call(report)
    ModeratorMailer.with(report: report).new_report.deliver_later if SiteSettings.email_configured?
  end
end
