class Components::PasswordInputRow < Components::InputRow
  def initialize(form:, attribute:, label:, strength_meter: false, help: nil, options: {})
    @strength_meter = strength_meter
    @field_options = {class: "form-control"}.merge(options)
    if strength_meter
      @field_options["data-controller"] = "zxcvbn"
      @field_options["data-action"] = "input->zxcvbn#onInput"
    end
    super(form: form, attribute: attribute, label: label, help: help, options: options)
  end

  def input_group
    div do
      raw @form.password_field(@attribute, @field_options) # rubocop:disable Rails/OutputSafety
      strength_meter
    end
  end

  def strength_meter
    return unless @strength_meter
    div class: "progress" do
      div class: "progress-bar w-0 zxcvbn-meter", data: {zxcvbn_min_score: Devise.min_password_score} do
        whitespace
      end
    end
  end
end
