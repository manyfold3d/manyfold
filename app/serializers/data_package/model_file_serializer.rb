module DataPackage
  class ModelFileSerializer < BaseSerializer
    def serialize
      return if !@object.persisted? || @object.basename == "datapackage.json"
      {
        name: @object.basename.parameterize,
        path: @object.filename,
        mediatype: @object.mime_type,
        caption: @object.caption,
        description: @object.notes,
        up: @object.up_direction,
        presupported: @object.presupported
      }.compact
    end
  end
end
