class Components::CheckBoxInputRow < Components::InputRow
  def input_element
    div class: "form-switch" do
      @form.check_box(@attribute, {class: "form-check-input form-check-inline"}.merge(@options))
    end
  end
end
