# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "ModelFiles", :after_first_run, :multiuser do # rubocop:disable RSpec/EmptyExampleGroup
  path "/models/{model_id}/model_files/{id}" do
    let(:model) { create(:model, creator: create(:creator), collection: create(:collection)) }
    let(:file) { create(:model_file, model: model) }

    let(:model_id) { model.to_param }
    let(:id) { file.to_param }

    get "Details of a single file in a model" do
      tags "Files"
      produces Mime[:manyfold_api_v0].to_s
      parameter name: :model_id, in: :path, type: :string, required: true, example: "abc123"
      parameter name: :id, in: :path, type: :string, required: true, example: "def456"
      security [client_credentials: ["public", "read"]]

      response "200", "Success" do
        schema type: :object,
          properties: {
            "@context": {"$ref" => "#/components/schemas/jsonld_context"},
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
            "spdx:license": {"$ref" => "#/components/schemas/spdxLicense"},
            creator: {
              type: :object,
              properties: {
                "@id": {type: :string, example: "https://example.com/creators/abc123"},
                "@type": {type: :string, example: "Organization"}
              }
            }
          },
          required: ["@context", "@id", "@type", "name", "isPartOf", "encodingFormat"]

        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "read").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "401", "Unuthorized; the request did not provide valid authentication details" do
        let(:Authorization) { nil } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "403", "Forbidden; the provided credentials do not have permission to perform the requested action" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end
  end
end
