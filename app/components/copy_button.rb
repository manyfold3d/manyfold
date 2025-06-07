class Components::CopyButton < Components::Base
  def initialize(text:)
    @text = text
  end

  def view_template
    a href: "#", class: "link-secondary", data: {controller: "copy-text", action: "click->copy-text#copy:prevent", copy_text_text_value: @text} do
      Icon icon: "clipboard-plus", label: t("components.copy_button.copy")
    end
  end
end
