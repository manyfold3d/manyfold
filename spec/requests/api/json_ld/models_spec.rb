# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "Models", :multiuser do # rubocop:disable RSpec/EmptyExampleGroup
  before do
    create(:admin)
    create_list(:model, 10, :public, creator: create(:creator, :public), collection: create(:collection, :public))
  end

  path "/models" do
    get "A list of models" do
      tags "Models"
      produces "application/ld+json"
      parameter name: :page, in: :query, type: :integer, example: 1, description: "Specify which page of results to retrieve.", required: false
      parameter name: :order, in: :query, type: :string, enum: ["name", "recent"], description: "Specify order of results; either by name or creation time", example: "name", required: false

      response "200", "Success" do
        schema type: :object,
          properties: {
            "@context": {"$ref" => "#/components/schemas/jsonld_context"},
            "@id": {type: :string, example: "https://example.com/models"},
            "@type": {type: :string, example: "hydra:Collection"},
            totalItems: {type: :integer, example: 42},
            member: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  "@id": {type: :string, example: "/models/abc123", description: "The URL of the model"},
                  "@type": {type: :string, example: "3DModel"},
                  name: {type: :string, example: "Model", description: "The human name of the model"}
                },
                required: ["@id", "name"]
              }
            },
            view: {
              type: :object,
              properties: {
                "@id": {type: :string, example: "https://example.com/models?page=2"},
                "@type": {type: :string, example: "hydra:PartialCollectionView"},
                first: {type: :string, example: "https://example.com/models?page=1"},
                prev: {type: :string, example: "https://example.com/models?page=1"},
                next: {type: :string, example: "https://example.com/models?page=3"},
                last: {type: :string, example: "https://example.com/models?page=10"}
              },
              required: ["@id", "@type", "first", "last"]
            }
          },
          required: ["@context", "@id", "@type", "totalItems", "member", "view"]

        run_test!
      end
    end
  end
  path "/models/{id}" do
    get "Details of a single model" do
      tags "Models"
      produces "application/ld+json"
      parameter name: :id, in: :path, type: :string, required: true, example: "abc123"

      response "200", "Success" do
        schema type: :object,
          properties: {
            "@context": {"$ref" => "#/components/schemas/jsonld_context"},
            "@id": {type: :string, example: "https://example.com/models/abc123"},
            "@type": {type: :string, example: "3DModel"},
            name: {type: :string, example: "3D Benchy"},
            description: {type: :string, example: "Lorem ipsum dolor sit amet...", description: "A longer description for the model. Can contain Markdown syntax."},
            hasPart: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  "@id": {type: :string, example: "https://example.com/models/abc123/model_files/def456"},
                  "@type": {type: :string, example: "3DModel"},
                  name: {type: :string, example: "Benchy"},
                  encodingFormat: {type: :string, example: "model/stl"}
                }
              },
              required: ["@id", "@type", "name", "encodingFormat"]
            },
            "spdx:license": {"$ref" => "#/components/schemas/spdxLicense"},
            isPartOf: {type: :object, properties: {
              "@id": {type: :string, example: "https://example.com/collections/abc123"},
              "@type": {type: :string, example: "Collection"}
            }}
            # creator: {
            #   type: :object,
            #   properties: {
            #     "@id": {type: :string, example: "https://example.com/creators/abc123"},
            #     "@type": {type: :string, example: "Organization"}
            #   }
            # }
          },
          required: ["@context", "@id", "@type", "name", "hasPart"]

        let(:id) { Model.first.to_param }
        run_test!
      end
    end
  end
end
