class Components::NumericInputRow < Components::InputRow
  def initialize(form:, attribute:, label:, unit: nil, help: nil, options: {})
    @unit = unit
    super(form: form, attribute: attribute, label: label, help: help, options: options)
  end

  def input_element
    raw @form.number_field(@attribute, {class: "form-control"}.merge(@options)) # rubocop:disable Rails/OutputSafety
    span(class: "input-group-text") { @unit } if @unit
  end
end
