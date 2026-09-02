# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "ModelFiles", :after_first_run, :multiuser do # rubocop:disable RSpec/EmptyExampleGroup
  path "/models/{model_id}/model_files" do
    post "Add a new file to a model" do
      tags "Files"
      consumes Mime[:manyfold_api_v0].to_s
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["write"]]

      parameter name: :model_id, in: :path, type: :string, required: true, example: "abc123"
      parameter name: :body, in: :body, schema: ManyfoldApi::V0::UploadedFileDeserializer.schema_ref

      let(:model) { create(:model, :with_collection, library: Library.default, creator: create(:creator)) }
      let(:model_id) { model.to_param }

      response "202", "Accepted; the files will be added to the model after processing" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) {
          {
            files: [
              id: "https://example.com/uploads/tus_id",
              name: "test.stl"
            ]
          }
        }

        run_test! do # rubocop:disable RSpec/ExampleLength
          expect(AddUploadedFileToModelJob).to have_been_enqueued.with(model.id, {
            id: "https://example.com/uploads/tus_id",
            name: "test.stl"
          }).once
        end
      end

      response "401", "Unauthorized; the request did not provide valid authentication details" do
        let(:Authorization) { nil } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "403", "Forbidden; the provided credentials do not have permission to perform the requested action" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end
  end

  path "/models/{model_id}/model_files/{id}" do
    parameter name: :model_id, in: :path, type: :string, required: true, example: "abc123"
    parameter name: :id, in: :path, type: :string, required: true, example: "def456"

    let(:model) { create(:model, :with_collection, creator: create(:creator)) }
    let(:file) { create(:model_file, model: model) }
    let(:supported_file) { create(:model_file, model: model, presupported: true, relationships_attributes: [{objekt: file, predicate: "supported_version_of"}]) }

    let(:model_id) { model.to_param }
    let(:id) { file.to_param }

    get "Details of a single file in a model" do
      tags "Files"
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["public", "read"]]

      response "200", "Success" do
        schema ManyfoldApi::V0::ModelFileSerializer.schema_ref

        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "read").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test! "produces valid linked data" do
          graph = RDF::Graph.new << JSON::LD::API.toRdf(response.parsed_body)
          expect(graph).to be_valid
        end

        run_test! "includes raw content URL" do
          expect(response.parsed_body["contentUrl"]).to eq "/models/#{model.to_param}/raw/#{file.filename}"
        end
      end

      response "401", "Unauthorized; the request did not provide valid authentication details" do
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
        schema ManyfoldApi::V0::ModelFileSerializer.schema_ref
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:new_supported_file) { create(:model_file, model: model, presupported: true) }
        let(:body) {
          {
            "description" => "lorem ipsum etc",
            "related" => [{
              "@id" => "http://localhost:3214/models/#{model_id}/model_files/#{new_supported_file.to_param}",
              "relationship" => "presupported_version"
            }]
          }
        }

        run_test! do # rubocop:disable RSpec/MultipleExpectations
          graph = RDF::Graph.new << JSON::LD::API.toRdf(response.parsed_body)
          expect(graph).to be_valid
          expect(response.parsed_body["description"]).to eq "lorem ipsum etc"
          expect(response.parsed_body.dig("related", 0, "@id")).to eq "http://localhost:3214/models/#{model_id}/model_files/#{new_supported_file.to_param}"
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

      response "401", "Unauthorized; the request did not provide valid authentication details" do
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

      response "401", "Unauthorized; the request did not provide valid authentication details" do
        let(:Authorization) { nil } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "403", "Forbidden; the provided credentials do not have permission to perform the requested action" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end
  end

  path "/models/{model_id}/raw/{filename}" do
    parameter name: :model_id, in: :path, type: :string, required: true, example: "abc123"
    parameter name: :filename, in: :path, type: :string, required: true, example: "supported/model.stl"

    let(:model) { create(:model, :with_collection, creator: create(:creator)) }
    let(:file) { create(:model_file, model: model) }

    let(:model_id) { model.to_param }
    let(:filename) { file.filename }

    get "Raw file data" do
      tags "Files"
      security [client_credentials: ["public", "read"]]

      response "200", "Success" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "read").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test! do
          expect(response.content_type).to eq "model/stl"
        end
      end

      response "401", "Unauthorized; the request did not provide valid authentication details" do
        let(:Authorization) { nil } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "403", "Forbidden; the provided credentials do not have permission to perform the requested action" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end

    put "Replace file content" do
      tags "Files"
      security [client_credentials: ["write"]]

      parameter in: :header, name: "Content-Length", description: "The number of bytes being sent in the PUT body", example: 128, required: true
      parameter in: :header, name: "Content-Type", description: "The media type of the file being uploaded. Must match the existing file", example: "model/stl", required: true
      parameter in: :body, name: :body
      metadata[:operation][:requestBody] = {
        required: true,
        description: "New file content to replace the current contents.",
        content: {
          "*/*": {
            schema: {
              type: "string",
              format: "binary"
            }
          }
        }
      }

      response "200", "Success" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) { "solid xxxxxxxxxxxx" }
        let(:"Content-Type") { "model/stl" } # rubocop:disable RSpec/VariableName
        let(:"Content-Length") { 18 } # rubocop:disable RSpec/VariableName

        run_test! do  # rubocop:disable RSpec/MultipleExpectations
          expect(file.reload.attachment.read).to eq "solid xxxxxxxxxxxx"
          expect(Scan::ModelFile::ParseMetadataJob).to have_been_enqueued
        end
      end

      response "400", "Bad Request" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) { "solid xxxxxxxxxxxx" }
        let(:"Content-Type") { "model/obj" } # rubocop:disable RSpec/VariableName
        let(:"Content-Length") { 18 } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "401", "Unauthorized; the request did not provide valid authentication details" do
        let(:Authorization) { nil } # rubocop:disable RSpec/VariableName
        let(:body) { nil }
        let(:"Content-Type") { "application/octet-stream" } # rubocop:disable RSpec/VariableName
        let(:"Content-Length") { 0 } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "403", "Forbidden; the provided credentials do not have permission to perform the requested action" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "read").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) { nil }
        let(:"Content-Type") { "application/octet-stream" } # rubocop:disable RSpec/VariableName
        let(:"Content-Length") { 0 } # rubocop:disable RSpec/VariableName

        run_test!
      end
    end
  end
end
