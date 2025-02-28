module DataPackage
  class ModelFileSerializer < BaseSerializer
    def serialize
      return if !@object.persisted? || @object.basename == "datapackage.json"
      {
        name: @object.basename.parameterize,
        path: @object.filename,
        mediatype: @object.mime_type
      }
    end
  end
end
