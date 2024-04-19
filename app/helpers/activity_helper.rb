module ActivityHelper
  def status_icon(status)
    case status
    when :queued
      icon "hourglass", t(".queued")
    when :working
      icon "gear", t(".working")
    when :completed
      icon "check2-circle", t(".completed")
    when :failed
      icon "exclamation-diamond", t(".error")
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
