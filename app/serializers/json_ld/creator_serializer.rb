module JsonLd
  class CreatorSerializer < ApplicationSerializer
    def serialize
      creator_ref(@object).merge(
        "@context": "https://schema.org/Organization",
        name: @object.name,
        description: @object.notes
      )
    end
  end
end
