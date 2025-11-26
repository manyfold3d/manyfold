class Components::CopyableText < Components::Base
  def initialize(text:, label: nil, obfuscated: false)
    @text = text
    @label = label
    @obfuscated = obfuscated
  end

  def before_template
    @label ||= t("components.copy_button.copy")
  end

  def view_template
    div do
      span(class: @obfuscated ? "obfuscated" : nil) { @text }
      whitespace
      if @obfuscated
        button class: "btn btn-sm btn-outline-secondary", title: t("components.copyable_text.reveal") do
          Icon icon: "eye"
        end
      end
      whitespace
      button class: "btn btn-sm btn-outline-secondary", title: @label, data: {controller: "copy-text", action: "click->copy-text#copy:prevent", copy_text_text_value: @text} do
        Icon icon: "clipboard-plus"
      end
    end
  end
end
