# frozen_string_literal: true

class Components::DisplayUserQuota < Components::Base
  include Phlex::Rails::Helpers::NumberToHumanSize

  def initialize(current_size:, quota:)
    @quota = quota.to_f
    @current_size = current_size.to_f
  end

  def view_template
    quota_in_mb = number_to_human_size(@quota)
    current_size_in_mb = number_to_human_size(@current_size)
    percent_used = ((@current_size / @quota) * 100).ceil
    progress_bar_background = "text-bg-success"
    case percent_used
    when 0..60
      progress_bar_background = "text-bg-success"
    when 70..90
      progress_bar_background = "text-bg-warning"
    when 90..Float::INFINITY
      progress_bar_background = "text-bg-danger"
    end
    h1 do
      plain "#{current_size_in_mb}/#{quota_in_mb}"
    end
    div class: "progress", role: %(progressbar), "aria-label": "Quota progress bar", "aria-valuemin": 0, "aria-valuemax": 100, "aria-value": percent_used do
      div class: "progress-bar #{progress_bar_background}", style: "width:#{percent_used}%" do
        "#{percent_used}%"
      end
    end
  end
end
