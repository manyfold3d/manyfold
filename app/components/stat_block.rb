# frozen_string_literal: true

class Components::StatBlock < Components::Base
  def initialize(title:, value:)
    @title = title
    @value = value
  end

  def view_template
    div(class: "badge text-bg-info col me-2") do
      div { @title.respond_to?(:model_name) ? @title.model_name.human(count: 100) : @title.to_s }
      div(class: "fs-4 mt-2 ") { @value.to_s }
    end
  end
end
