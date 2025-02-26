module DataPackage
  class CreatorSerializer < BaseSerializer
    def serialize
      {
        title: @object.name,
        path: Rails.application.routes.url_helpers.url_for(@object),
        roles: ["creator"]
      }
    end
  end
end
