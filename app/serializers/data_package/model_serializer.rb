module DataPackage
  class ModelSerializer < BaseSerializer
    def serialize
      {
        "$schema": "https://manyfold.app/profiles/0.0/datapackage.json",
        name: @object.name.parameterize,
        title: @object.name,
        caption: @object.caption,
        description: @object.notes,
        homepage: Rails.application.routes.url_helpers.url_for(@object),
        image: @object.preview_file&.is_image? ? @object.preview_file.filename : nil,
        keywords: @object.tag_list,
        licenses: (@object.license ? [
          {
            name: @object.license,
            path: Spdx.licenses.dig(@object.license, "reference")
          }.compact
        ] : nil),
        resources: @object.model_files.filter_map { |it| ModelFileSerializer.new(it).serialize },
        sensitive: @object.sensitive,
        contributors: @object.creator ? [CreatorSerializer.new(@object.creator).serialize] : nil,
        collections: @object.collection ? [CollectionSerializer.new(@object.collection).serialize] : nil,
        links: @object.links.map { |it| LinkSerializer.new(it).serialize }
      }.compact
    end
  end
end
