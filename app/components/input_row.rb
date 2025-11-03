class Components::InputRow < Components::Base
  def initialize(form:, attribute:, label:, help: nil, options: {})
    @form = form
    @attribute = attribute
    @label = label
    @help = help
    @options = options
  end

  def view_template
    div do
      @form.label(@attribute, @label, class: "col-form-label")
    end
    div do
      input_group
      errors_for(@form.object, @attribute)
      span(class: "form-text") { @help } if @help
    end
  end

  def input_group
    div class: "input-group" do
      input_element
    end
  end

  def input_element
    raise NotImplementedError
  end

  def errors_for(object, attribute)
    return if object.nil? || attribute.nil?
    return unless object.errors.include? attribute
    div class: "invalid-feedback d-block" do
      object.errors.full_messages_for(attribute).join("; ")
    end
  end
end
