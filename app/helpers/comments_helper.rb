module CommentsHelper
  def link_to_reportable(report)
    reportable = report.object.try(:entity) || report.object
    return if reportable.nil?
    if reportable.is_a? User
      link_to reportable.username, settings_user_path(reportable)
    elsif reportable.is_a? Comment
      link_to reportable.name, reportable.commentable
    else
      link_to reportable.name, reportable
    end
  end
end
