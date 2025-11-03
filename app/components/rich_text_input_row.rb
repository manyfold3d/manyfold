class Components::RichTextInputRow < Components::InputRow
  def input_element
    @form.text_area(@attribute, {class: "form-control"}.merge(@options))
  end
end
