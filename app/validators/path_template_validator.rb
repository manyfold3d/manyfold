class PathTemplateValidator < ActiveModel::EachValidator
  VALID_TOKENS = [
    "tags",
    "creator",
    "collection",
    "collections",
    "modelName",
    "modelId"
  ]

  def validate_each(record, attribute, value)
    tokens = value.scan(/\{([a-zA-Z]+)\}/).flatten
    tokens.each do |token|
      unless token.in? VALID_TOKENS
        record.errors.add attribute, :invalid
        break
      end
    end
  end
end
