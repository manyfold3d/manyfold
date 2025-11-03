class Components::UrlInputRow < Components::InputRow
  def input_element
    @form.url_field(@attribute, {class: "form-control"}.merge(@options))
  end
end
