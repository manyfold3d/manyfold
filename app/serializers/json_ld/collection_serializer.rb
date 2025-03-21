module JsonLd
  class CollectionSerializer < ApplicationSerializer
    def serialize
      collection_ref(@object).merge(
        "@context": "https://schema.org/Collection",
        name: @object.name,
        description: @object.notes
      )
    end
  end
end
