module JsonLd
  class CreatorSerializer < ApplicationSerializer
    def serialize
      creator_ref(@object).merge(
        "@context": context,
        name: @object.name,
        description: @object.notes
      )
    end
  end
end
