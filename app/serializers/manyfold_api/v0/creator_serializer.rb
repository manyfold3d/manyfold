module ManyfoldApi::V0
  class CreatorSerializer < ApplicationSerializer
    def serialize
      creator_ref(@object).merge(
        "@context": context,
        name: @object.name,
        description: @object.notes
      ).compact
    end
  end
end
