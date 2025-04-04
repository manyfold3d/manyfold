module DataPackage
  class CollectionSerializer < BaseSerializer
    def serialize
      {
        title: @object.name,
        path: Rails.application.routes.url_helpers.url_for(@object),
        caption: @object.caption,
        description: @object.notes,
        links: @object.links.map { |it| LinkSerializer.new(it).serialize }
      }.compact
    end
  end
end
