module ManyfoldApi::V0
  class ApplicationSerializer
    def initialize(object)
      @object = object
    end

    def context
      [
        "https://schema.org/",
        {
          hydra: "http://www.w3.org/ns/hydra/core#",
          spdx: "http://spdx.org/rdf/terms#"
        }
      ]
    end

    def license(id)
      return if id.blank?
      {
        "@type": "spdx:License",
        "@id": id.starts_with?("LicenseRef-") ?
          nil :
          "http://spdx.org/licenses/#{id}",
        licenseId: id
      }.compact
    end

    def collection_ref(collection)
      return if collection.nil?
      ref id: Rails.application.routes.url_helpers.collection_url(collection), type: "Collection"
    end

    def creator_ref(creator)
      return if creator.nil?
      ref id: Rails.application.routes.url_helpers.creator_url(creator), type: "Organization"
    end

    def group_ref(group)
      return if group.nil?
      ref id: Rails.application.routes.url_helpers.creator_group_url(group.creator, group), type: "Group"
    end

    def model_ref(model)
      return if model.nil?
      ref id: Rails.application.routes.url_helpers.model_url(model), type: "3DModel"
    end

    def file_ref(file)
      return if file.nil?
      ref id: Rails.application.routes.url_helpers.model_model_file_url(file.model, file), type: "3DModel"
    end

    def ref(id:, type:)
      {
        "@id": id,
        "@type": type
      }
    end

    def self.schema_ref_name
      name.underscore.split("/").last.gsub("_serializer", "_response")
    end

    def self.schema_ref
      {"$ref" => "#/components/schemas/#{schema_ref_name}"}
    end

    def self.schema
      raise NotImplementedError
    end
  end
end
