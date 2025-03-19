module JsonLd
  class CreatorSerializer < ApplicationSerializer
    def serialize
      {
        "@context": "https://schema.org/Organization",
        "@id": Rails.application.routes.url_helpers.creator_path(@object),
        "@type": "Organization",
        name: @object.name,
        description: @object.notes
      }
    end
  end
end
