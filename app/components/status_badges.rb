# frozen_string_literal: true

class Components::StatusBadges < Components::Base
  register_output_helper :problem_icon_tag
  register_value_helper :problems_including_files
  register_value_helper :problem_settings
  register_value_helper :policy

  def initialize(model:)
    @model = model
  end

  def render?
    @model.present?
  end

  def view_template
    span class: "status-badges" do
      if @model.new?
        span class: "text-warning" do
          Icon(icon: "stars", label: t("general.new"))
        end
        whitespace
      end
      problem_icon_tag(problems_including_files(@model).visible(problem_settings)) if policy(Problem).show?
    end
  end
end
