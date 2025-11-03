class Components::SelectInputRow < Components::InputRow
  def initialize(form:, attribute:, label:, select_options:, help:, options: {})
    @select_options = select_options
    super(form: form, attribute: attribute, label: label, help: help, options: options)
  end

  def input_element
    raw @form.select( # rubocop:disable Rails/OutputSafety
      @attribute,
      @select_options,
      @options.compact,
      {
        data: {
          controller: "searchable-select"
        },
        class: "form-control form-select #{"is-invalid" if @form.object&.errors&.include?(@attribute_without_id) && !@form.object.errors[@attribute_without_id].empty?}"
      }
    )
    if @options[:button]
      a href: @options[:button][:path], class: "btn btn-secondary" do
        @options[:button][:label]
      end
    end
  end
end
