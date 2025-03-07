module OEmbed
  class CreatorSerializer < ApplicationSerializer
    def serialize
      {
        title: @object.name
      }.merge(
        generic_properties,
        link_properties
      )
    end
  end
end
