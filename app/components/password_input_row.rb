class Components::PasswordInputRow < Components::InputRow
  def initialize(form:, attribute:, label:, help: nil, options: {})
    @field_options = {class: "form-control"}.merge(options)
    super
  end

  def input_group
    div class: "input-group" do
      raw @form.password_field(@attribute, @field_options) # rubocop:disable Rails/OutputSafety
    end
  end
end
