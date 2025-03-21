# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "ModelFiles", :multiuser do # rubocop:disable RSpec/EmptyExampleGroup
  before do
    create(:admin)
    create(:model_file, model: create(:model, :public))
  end

  path "/models/{model_id}/model_files/{id}" do
    get "Details of a single file in a model" do
      tags "Files"
      produces "application/ld+json"
      parameter name: :model_id, in: :path, type: :string, required: true, example: "abc123"
      parameter name: :id, in: :path, type: :string, required: true, example: "def456"

      response "200", "Success" do
        schema type: :object,
          properties: {
            "@context": {type: :array, items: {type: :string, example: "https://schema.org/3DModel"}},
            "@id": {type: :string, example: "https://example.com/models/abc123/model_files/def456"},
            "@type": {type: :string, example: "3DModel"},
            name: {type: :string, example: "Benchy"},
            isPartOf: {type: :object, properties: {
              "@id": {type: :string, example: "https://example.com/models/abc123"},
              "@type": {type: :string, example: "3DModel"}
            }},
            encodingFormat: {type: :string, example: "model/stl"},
            contentUrl: {type: :string, example: "https://example.com/models/abc123/model_files/def456.stl"},
            contentSize: {type: :integer, example: 12345},
            description: {type: :string, example: "Lorem ipsum dolor sit amet...", description: "A longer description for the file. Can contain Markdown syntax."},
            license: {
              type: :object,
              properties: {
                "@id": {type: :string, example: "http://spdx.org/licenses/MIT"},
                licenseId: {type: :string, example: "MIT"}
              },
              required: ["licenseId"]
            }
          },
          required: ["@context", "@id", "@type", "name", "isPartOf", "encodingFormat"]

        let(:model_id) { Model.first.to_param }
        let(:id) { ModelFile.first.to_param }
        run_test!
      end
    end
  end
end
