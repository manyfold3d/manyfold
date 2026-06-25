module MediaType
  CATEGORIES = {}

  class << self
    prepend MemoWise

    def register(type, symbol, category:, additional_types: [], additional_extensions: [])
      Mime::Type.register type, symbol, additional_types, additional_extensions
      categorize(symbol, category)
    end

    def categorize(symbol, category)
      CATEGORIES[category] ||= []
      CATEGORIES[category] << symbol
    end

    def image_types
      category_types :image
    end

    def image_extensions
      category_extensions :image
    end

    def video_types
      category_types :video
    end

    def video_extensions
      category_extensions :video
    end

    def document_types
      category_types :document
    end

    def document_extensions
      category_extensions :document
    end

    def archive_types
      category_types :archive
    end

    def archive_extensions
      category_extensions :archive
    end

    def model_types
      category_types :model
    end

    def model_extensions
      category_extensions :model
    end

    def slicer_types
      category_types :slicer
    end

    def slicer_extensions
      category_extensions :slicer
    end

    def indexable_types
      image_types + model_types + video_types + document_types + archive_types + slicer_types
    end
    memo_wise :indexable_types

    def indexable_extensions
      image_extensions + model_extensions + video_extensions + document_extensions + archive_extensions + slicer_extensions
    end
    memo_wise :indexable_extensions

    private

    def category_types(category)
      Mime::LOOKUP.filter { |k, v| is_in_category?(v, category) }.values
    end
    memo_wise :category_types

    def category_extensions(category)
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_in_category?(v, category) }.keys
    end
    memo_wise :category_extensions

    def is_in_category?(type, category)
      type.to_sym.in? MediaType::CATEGORIES.fetch(category, [])
    end
    memo_wise :is_in_category?
  end
end
