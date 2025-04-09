# frozen_string_literal: true

class StatBlockComponent < ViewComponent::Base
  def initialize(title:, value:)
    @title = title
    @value = value
  end

  def call
    content_tag :div, class: "badge text-bg-info col me-2" do
      safe_join([
        content_tag(:div) { @title.respond_to?(:model_name) ? @title.model_name.human(count: 100) : @title.to_s },
        content_tag(:div, class: "fs-4 mt-2 ") { @value.to_s }
      ])
    end
  end
end
