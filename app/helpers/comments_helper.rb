module CommentsHelper
  def link_to_reportable(report)
    reportable = report.object&.entity
    return if reportable.nil?
    if reportable.is_a? User
      link_to reportable.username, settings_user_path(reportable)
    else
      link_to reportable.name, reportable
    end
  end
end
