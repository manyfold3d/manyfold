module SupportedMimeTypes
  class << self
    prepend MemoWise

    def image_types
      Mime::LOOKUP.filter { |k, v| is_in_category?(v, :image) }.values
    end
    memo_wise :image_types

    def image_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_in_category?(v, :image) }.keys
    end
    memo_wise :image_extensions

    def video_types
      Mime::LOOKUP.filter { |k, v| is_in_category?(v, :video) }.values
    end
    memo_wise :video_types

    def video_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_in_category?(v, :video) }.keys
    end
    memo_wise :video_extensions

    def document_types
      Mime::LOOKUP.filter { |k, v| is_in_category?(v, :document) }.values
    end
    memo_wise :document_types

    def document_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_in_category?(v, :document) }.keys
    end
    memo_wise :document_extensions

    def archive_types
      Mime::LOOKUP.filter { |k, v| is_in_category?(v, :archive) }.values
    end
    memo_wise :archive_types

    def archive_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_in_category?(v, :archive) }.keys
    end
    memo_wise :archive_extensions

    def model_types
      Mime::LOOKUP.filter { |k, v| is_in_category?(v, :model) }.values
    end
    memo_wise :model_types

    def model_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_in_category?(v, :model) }.keys
    end
    memo_wise :model_extensions

    def slicer_types
      Mime::LOOKUP.filter { |k, v| is_in_category?(v, :slicer) }.values
    end
    memo_wise :slicer_types

    def slicer_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_in_category?(v, :slicer) }.keys
    end
    memo_wise :slicer_extensions

    def indexable_types
      image_types + model_types + video_types + document_types + archive_types + slicer_types
    end
    memo_wise :indexable_types

    def indexable_extensions
      image_extensions + model_extensions + video_extensions + document_extensions + archive_extensions + slicer_extensions
    end
    memo_wise :indexable_extensions

    private

    def is_in_category?(type, category)
      type.to_sym.in? MediaType::CATEGORIES.fetch(category, [])
    end
    memo_wise :is_in_category?
  end
end
