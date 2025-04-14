# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "ModelFiles", :after_first_run, :multiuser do # rubocop:disable RSpec/EmptyExampleGroup
  path "/models/{model_id}/model_files/{id}" do
    parameter name: :model_id, in: :path, type: :string, required: true, example: "abc123"
    parameter name: :id, in: :path, type: :string, required: true, example: "def456"

    let(:model) { create(:model, creator: create(:creator), collection: create(:collection)) }
    let(:file) { create(:model_file, model: model) }

    let(:model_id) { model.to_param }
    let(:id) { file.to_param }

    get "Details of a single file in a model" do
      tags "Files"
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["public", "read"]]

      response "200", "Success" do
        schema({"$ref": "#/components/schemas/model_file_response"})

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

    patch "Update file details" do
      tags "Files"
      consumes Mime[:manyfold_api_v0].to_s
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["write"]]
      parameter name: :body, in: :body, schema: ManyfoldApi::V0::ModelFileDeserializer.schema_ref

      response "200", "File updated" do
        schema({"$ref": "#/components/schemas/model_file_response"})
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) { {"description" => "lorem ipsum etc"} }

        run_test! do
          expect(response.parsed_body["description"]).to eq "lorem ipsum etc"
        end
      end

      response "400", "The request structure was incorrect" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "422", "Update failed due to invalid data" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) { {"filename" => ""} }

        run_test! do
          expect(response.parsed_body["filename"]).to include("can't be blank")
        end
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

    delete "Remove a single file" do
      tags "Files"
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["delete"]]
      response "204", "Success" do
        schema type: nil
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "delete").plaintext_token}" } # rubocop:disable RSpec/VariableName

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
