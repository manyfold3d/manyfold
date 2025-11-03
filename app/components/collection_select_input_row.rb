class Components::CollectionSelectInputRow < Components::SelectInputRow
  register_value_helper :options_from_collection_for_select

  def initialize(form:, attribute:, label:, collection:, text_method:, help:, value_method: :id, options: {})
    @collection = collection
    @value_method = value_method
    @text_method = text_method
    super(form: form, attribute: "#{attribute}_#{value_method}", label: label, select_options: [], help: help, options: options)
  end

  def before_template
    @select_options = options_from_collection_for_select(@collection, @value_method, @text_method, @form&.object&.send(@attribute))
  end
end
