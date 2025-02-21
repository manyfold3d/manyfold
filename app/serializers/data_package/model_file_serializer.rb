module DataPackage
  class ModelFileSerializer < BaseSerializer
    def serialize
      {
        name: @object.basename.parameterize,
        path: @object.filename,
        mediatype: @object.mime_type
      }
    end
  end
end
