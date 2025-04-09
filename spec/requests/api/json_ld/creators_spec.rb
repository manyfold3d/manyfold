# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "Creators", :after_first_run, :multiuser do # rubocop:disable RSpec/EmptyExampleGroup
  before do
    create_list(:creator, 10, :public)
  end

  path "/creators" do
    get "A list of creators" do
      tags "Creators"
      produces "application/ld+json"
      parameter name: :page, in: :query, type: :integer, example: 1, description: "Specify which page of results to retrieve.", required: false
      parameter name: :order, in: :query, type: :string, enum: ["name", "recent"], description: "Specify order of results; either by name or creation time", example: "name", required: false
      security [client_credentials: ["read"]]

      response "200", "Success" do
        schema type: :object,
          properties: {
            "@context": {"$ref" => "#/components/schemas/jsonld_context"},
            "@id": {type: :string, example: "https://example.com/creators"},
            "@type": {type: :string, example: "hydra:Collection"},
            totalItems: {type: :integer, example: 42},
            member: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  "@id": {type: :string, example: "/creators/abc123", description: "The URL of the creator"},
                  name: {type: :string, example: "Fred", description: "The human name of the creator"}
                },
                required: ["@id", "name"]
              }
            },
            view: {
              type: :object,
              properties: {
                "@id": {type: :string, example: "https://example.com/creators?page=2"},
                "@type": {type: :string, example: "hydra:PartialCollectionView"},
                first: {type: :string, example: "https://example.com/creators?page=1"},
                prev: {type: :string, example: "https://example.com/creators?page=1"},
                next: {type: :string, example: "https://example.com/creators?page=3"},
                last: {type: :string, example: "https://example.com/creators?page=10"}
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

  path "/creators/{id}" do
    get "Details of a single creator" do
      tags "Creators"
      produces "application/ld+json"
      parameter name: :id, in: :path, type: :string, required: true, example: "abc123"
      security [client_credentials: ["read"]]

      response "200", "Success" do
        schema type: :object,
          properties: {
            "@context": {"$ref" => "#/components/schemas/jsonld_context"},
            "@id": {type: :string, example: "https://example.com/creators/abc123"},
            "@type": {type: :string, example: "Organization"},
            name: {type: :string, example: "Bruce Wayne"},
            description: {type: :string, example: "Lorem ipsum dolor sit amet...", description: "A longer description for the creator. Can contain Markdown syntax."}
          },
          required: ["@context", "@id", "@type", "name"]

        let(:Authorization) { "Bearer #{create(:oauth_access_token).plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:id) { Creator.first.to_param }
        run_test!
      end
    end
  end
end
