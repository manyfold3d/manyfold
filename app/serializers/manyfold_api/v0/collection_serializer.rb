module ManyfoldApi::V0
  class CollectionSerializer < ApplicationSerializer
    def serialize
      collection_ref(@object).merge(
        "@context": context,
        name: @object.name,
        description: @object.notes,
        creator: creator_ref(@object.creator),
        isPartOf: collection_ref(@object.collection)
      ).compact
    end
  end
end
