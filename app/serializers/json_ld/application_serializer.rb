module JsonLd
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
        "@id": id.starts_with?("LicenseRef-") ?
          nil :
          "http://spdx.org/licenses/#{id}",
        licenseId: id
      }.compact
    end

    def collection_ref(collection)
      return if collection.nil?
      ref id: Rails.application.routes.url_helpers.collection_path(collection), type: "Collection"
    end

    def creator_ref(creator)
      return if creator.nil?
      ref id: Rails.application.routes.url_helpers.creator_path(creator), type: "Organization"
    end

    def model_ref(model)
      return if model.nil?
      ref id: Rails.application.routes.url_helpers.model_path(model), type: "3DModel"
    end

    def file_ref(file)
      return if file.nil?
      ref id: Rails.application.routes.url_helpers.model_model_file_path(file.model, file), type: "3DModel"
    end

    def ref(id:, type:)
      {
        "@id": id,
        "@type": type
      }
    end
  end
end
