# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "Models", :multiuser do # rubocop:disable RSpec/EmptyExampleGroup
  before { create(:admin) }

  path "/models" do
    get "Model list" do
      produces "application/ld+json"

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
            }
          },
          required: ["@context", "@id", "@type", "totalItems", "member"]

        run_test!
      end
    end
  end
end
