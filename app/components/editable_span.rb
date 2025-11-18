# frozen_string_literal: true

class Components::EditableSpan < Components::Base
  def initialize(fieldname:, path:, text:)
    @fieldname = fieldname
    @path = path
    @text = text
  end

  def view_template
    span(
      class: "editable p-1",
      contenteditable: "plaintext-only",
      data: {
        editable_field: @fieldname,
        editable_path: @path,
        controller: "editable",
        action: "focus->editable#onFocus blur->editable#onBlur keypress->editable#onKeypress"
      }
    ) do
      @text
    end
  end
end
