module DataPackage
  class ModelSerializer < BaseSerializer
    def serialize
      {
        name: @object.name.parameterize,
        title: @object.name,
        description: [@object.caption, @object.notes].compact.join("\n\n"),
        homepage: Rails.application.routes.url_helpers.url_for(@object),
        image: @object.preview_file&.is_image? ? @object.preview_file.filename : nil,
        keywords: @object.tag_list,
        licenses: (@object.license ? [
          {
            name: @object.license,
            path: Spdx.licenses.dig(@object.license, "reference")
          }.compact
        ] : nil),
        resources: @object.model_files.map { |it| ModelFileSerializer.new(it).serialize },
        contributors: @object.creator ? [CreatorSerializer.new(@object.creator).serialize] : nil
      }.compact
    end
  end
end
