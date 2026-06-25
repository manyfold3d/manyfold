module MediaType
  CATEGORIES = {}

  def self.register(type, symbol, additional_types: [], additional_extensions: [], category: nil)
    Mime::Type.register type, symbol, additional_types, additional_extensions
    if category
      CATEGORIES[category] ||= []
      CATEGORIES[category] << symbol
    end
  end
end
