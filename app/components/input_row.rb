class Components::InputRow < Components::Base
  register_output_helper :errors_for

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
      div class: "input-group" do
        input_element
      end
      errors_for(@form.object, @attribute)
      span(class: "form-text") { @help } if @help
    end
  end

  def input_element
    raise NotImplementedError
  end
end
