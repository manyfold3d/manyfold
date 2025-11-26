class Components::CopyButton < Components::Base
  def initialize(text:, label: nil)
    @text = text
    @label = label
  end

  def before_template
    @label ||= t("components.copy_button.copy")
  end

  def view_template
    button class: "btn btn-secondary", data: {controller: "copy-text", action: "click->copy-text#copy:prevent", copy_text_text_value: @text} do
      Icon icon: "clipboard-plus", label: @label
    end
  end
end
