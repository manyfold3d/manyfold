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
    h1 do
      plain "#{current_size_in_mb}/#{quota_in_mb}"
    end
    div class: %(progress), role: %(progressbar), "aria-label": "Quota progress bar", "aria-valuemin": 0, "aria-valuemax": 100, "aria-value": percent_used do
      div class: "progress-bar", style: "width:#{percent_used}%"
    end
  end
end
