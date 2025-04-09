# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "Collections", :multiuser do # rubocop:disable RSpec/EmptyExampleGroup
  before do
    create(:admin)
    create_list(:collection, 10, :public)
  end

  path "/collections" do
    get "A list of collections" do
      tags "Collections"
      produces "application/ld+json"
      parameter name: :page, in: :query, type: :integer, example: 1, description: "Specify which page of results to retrieve.", required: false
      parameter name: :order, in: :query, type: :string, enum: ["name", "recent"], description: "Specify order of results; either by name or creation time", example: "name", required: false
      security [client_credentials: ["read"]]

      response "200", "Success" do
        schema type: :object,
          properties: {
            "@context": {"$ref" => "#/components/schemas/jsonld_context"},
            "@id": {type: :string, example: "https://example.com/collections"},
            "@type": {type: :string, example: "hydra:Collection"},
            totalItems: {type: :integer, example: 42},
            member: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  "@id": {type: :string, example: "/collections/abc123", description: "The URL of the collection"},
                  name: {type: :string, example: "Printer Parts", description: "The human name of the collection"}
                },
                required: ["@id", "name"]
              }
            },
            view: {
              type: :object,
              properties: {
                "@id": {type: :string, example: "https://example.com/collections?page=2"},
                "@type": {type: :string, example: "hydra:PartialCollectionView"},
                first: {type: :string, example: "https://example.com/collections?page=1"},
                prev: {type: :string, example: "https://example.com/collections?page=1"},
                next: {type: :string, example: "https://example.com/collections?page=3"},
                last: {type: :string, example: "https://example.com/collections?page=10"}
              },
              required: ["@id", "@type", "first", "last"]
            }
          },
          required: ["@context", "@id", "@type", "totalItems", "member", "view"]

        let(:Authorization) { "Bearer #{create(:oauth_access_token).plaintext_token}" } # rubocop:disable RSpec/VariableName
        run_test!
      end
    end
  end

  path "/collections/{id}" do
    get "Details of a single collection" do
      tags "Collections"
      produces "application/ld+json"
      parameter name: :id, in: :path, type: :string, required: true, example: "abc123"
      security [client_credentials: ["read"]]

      response "200", "Success" do
        schema type: :object,
          properties: {
            "@context": {"$ref" => "#/components/schemas/jsonld_context"},
            "@id": {type: :string, example: "https://example.com/collections/abc123"},
            "@type": {type: :string, example: "Collection"},
            name: {type: :string, example: "Interesting Things"},
            description: {type: :string, example: "Lorem ipsum dolor sit amet...", description: "A longer description for the collection. Can contain Markdown syntax."},
            creator: {
              type: :object,
              properties: {
                "@id": {type: :string, example: "https://example.com/creators/abc123"},
                "@type": {type: :string, example: "Organization"}
              }
            }
          },
          required: ["@context", "@id", "@type", "name"]

        let(:Authorization) { "Bearer #{create(:oauth_access_token).plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:id) { Collection.first.to_param }
        run_test!
      end
    end
  end
end
