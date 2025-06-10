# frozen_string_literal: true

class Components::DisplayUserQuota < Components::Base
  include Phlex::Rails::Helpers::NumberToHumanSize

  def initialize(current_size:, quota:)
    @quota = quota
    @current_size = current_size
  end

  def view_template
    quota_in_MB = number_to_human_size(@quota)
    current_size_in_MB = number_to_human_size(@current_size)
    h1 do
      plain "#{current_size_in_MB}/#{quota_in_MB}"
    end
  end

end
