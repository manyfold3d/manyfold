module ActivityHelper
  def status_icon(status)
    case status
    when :queued
      render Components::Icon.new(icon: "hourglass", label: translate("activity_helper.status_icon.queued"))
    when :working
      render Components::Icon.new(icon: "gear", label: translate("activity_helper.status_icon.working"), effect: "icon-spin")
    when :completed
      render Components::Icon.new(icon: "check2-circle", label: translate("activity_helper.status_icon.completed"))
    when :failed
      render Components::Icon.new(icon: "exclamation-diamond", label: translate("activity_helper.status_icon.error"))
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
