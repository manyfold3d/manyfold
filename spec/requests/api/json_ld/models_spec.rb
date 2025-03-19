# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "Models", :multiuser do # rubocop:disable RSpec/EmptyExampleGroup
  before do
    create(:admin)
    create_list(:model, 10)
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
            "@context": {type: :string, example: "http://www.w3.org/ns/hydra/context.jsonld"},
            "@id": {type: :string, example: "https://example.com/models"},
            "@type": {type: :string, example: "Collection"},
            totalItems: {type: :integer, example: 42},
            member: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  "@id": {type: :string, example: "/models/abc123", description: "The URL of the model"},
                  name: {type: :string, example: "Model", description: "The human name of the model"}
                },
                required: ["@id", "name"]
              }
            },
            view: {
              type: :object,
              properties: {
                "@id": {type: :string, example: "https://example.com/models?page=2"},
                "@type": {type: :string, example: "PartialCollectionView"},
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
end
