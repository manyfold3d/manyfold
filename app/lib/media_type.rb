module MediaType
  CATEGORIES = {}

  def self.register(type, symbol, category:, additional_types: [], additional_extensions: [])
    Mime::Type.register type, symbol, additional_types, additional_extensions
    categorize(symbol, category)
  end

  def self.categorize(symbol, category)
    CATEGORIES[category] ||= []
    CATEGORIES[category] << symbol
  end
end
