module OEmbed
  class CollectionSerializer < ApplicationSerializer
    def serialize
      {
        title: @object.name
      }.merge(
        generic_properties,
        author_properties(@object.creator),
        model_file_properties(@object.models.first&.preview_file)
      )
    end
  end
end
