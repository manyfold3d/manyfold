module OEmbed
  class CollectionSerializer < ApplicationSerializer
    def serialize
      {
        title: @object.name
      }.merge(
        generic_properties,
        author_properties(@object.creator),
        model_file_properties(
          (ModelPolicy.new(nil, @object.preview_model).show? && @object.preview_model.preview_file) ||
          ModelPolicy::Scope.new(nil, @object.models).resolve.first&.preview_file
        )
      )
    end
  end
end
