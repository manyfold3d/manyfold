module ActivityHelper
  def status_icon(status)
    case status
    when :queued
      icon "hourglass", translate("activity_helper.status_icon.queued")
    when :working
      icon "gear", translate("activity_helper.status_icon.working")
    when :completed
      icon "check2-circle", translate("activity_helper.status_icon.completed")
    when :failed
      icon "exclamation-diamond", translate("activity_helper.status_icon.error")
    end
  end

  def activity_row_style(status)
    case status
    when :working
      "table-info"
    when :completed
      "table-success"
    when :failed
      "table-danger"
    end
  end
end
