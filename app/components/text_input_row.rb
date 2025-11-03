class Components::TextInputRow < Components::InputRow
  def input_element
    @form.text_field(@attribute, {class: "form-control"}.merge(@options))
  end
end
