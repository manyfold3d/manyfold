# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "Models", :after_first_run, :multiuser do # rubocop:disable RSpec/EmptyExampleGroup
  path "/models" do
    get "A list of models" do
      before do
        create_list(:model, 9, creator: create(:creator), collection: create(:collection))
        create_list(:model, 3, :public, creator: create(:creator, :public), collection: create(:collection, :public))
      end

      tags "Models"
      produces Mime[:manyfold_api_v0].to_s
      parameter name: :page, in: :query, type: :integer, example: 1, description: "Specify which page of results to retrieve.", required: false
      parameter name: :order, in: :query, type: :string, enum: ["name", "recent"], description: "Specify order of results; either by name or creation time", example: "name", required: false
      parameter name: :creator, in: :query, type: :string, description: "The ID of a creator to filter the model list", example: "abc123", required: false
      parameter name: :collection, in: :query, type: :string, description: "The ID of a collection to filter the model list", example: "abc123", required: false
      security [client_credentials: ["public", "read"]]

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

        context "with public scope" do
          let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "public").plaintext_token}" } # rubocop:disable RSpec/VariableName

          run_test! do
            expect(response.parsed_body["totalItems"]).to eq 3
          end
        end

        context "with read scope" do
          let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "read").plaintext_token}" } # rubocop:disable RSpec/VariableName

          run_test! "produces valid linked data" do
            graph = RDF::Graph.new << JSON::LD::API.toRdf(response.parsed_body)
            expect(graph).to be_valid
          end

          run_test! do
            expect(response.parsed_body["totalItems"]).to eq 12
          end
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

    path "/models" do
      post "Create new models from uploaded files" do
        tags "Models"
        consumes Mime[:manyfold_api_v0].to_s
        produces Mime[:manyfold_api_v0].to_s
        security [client_credentials: ["write"]]

        parameter name: :body, in: :body, schema: ManyfoldApi::V0::UploadedModelDeserializer.schema_ref

        before { create(:library) }

        response "202", "Accepted; the files will be processed and turned into new models" do
          let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
          let(:body) {
            {
              files: [
                id: "https://example.com/uploads/tus_id",
                name: "test.stl"
              ],
              "spdx:license": {
                licenseId: "MIT"
              },
              sensitive: true,
              keywords: ["tag1", "tag2"]
            }
          }

          run_test! do # rubocop:disable RSpec/ExampleLength
            expect(ProcessUploadedFileJob).to have_been_enqueued.with(
              Library.first.id,
              {
                id: "https://example.com/uploads/tus_id",
                storage: "cache",
                metadata: {
                  filename: "test.stl"
                }
              },
              owner: User.last,
              creator_id: nil,
              collection_id: nil,
              license: "MIT",
              sensitive: true,
              permission_preset: nil,
              tags: ["tag1", "tag2"]
            ).once
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
  end

  path "/models/{id}" do
    parameter name: :id, in: :path, type: :string, required: true, example: "abc123"
    let(:model) { create(:model) }
    let(:id) { model.to_param }

    get "Details of a single model" do
      tags "Models"
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["public", "read"]]

      response "200", "Success" do
        schema ManyfoldApi::V0::ModelSerializer.schema_ref

        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "read").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test! "produces valid linked data" do
          graph = RDF::Graph.new << JSON::LD::API.toRdf(response.parsed_body)
          expect(graph).to be_valid
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

    patch "Update a model" do
      tags "Models"
      consumes Mime[:manyfold_api_v0].to_s
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["write"]]
      parameter name: :body, in: :body, schema: ManyfoldApi::V0::ModelDeserializer.schema_ref

      response "200", "Model updated" do
        schema ManyfoldApi::V0::ModelSerializer.schema_ref
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:preview_file) { create(:model_file, model: model) }
        let(:body) {
          {"name" => "New Model Name",
           "preview_file" => {
             "@id" => "http://localhost:3214/models/#{id}/model_files/#{preview_file.to_param}"
           }}
        }

        run_test! "produces valid linked data" do
          graph = RDF::Graph.new << JSON::LD::API.toRdf(response.parsed_body)
          expect(graph).to be_valid
        end

        run_test! do
          expect(response.parsed_body["name"]).to eq "New Model Name"
        end

        run_test! do
          expect(response.parsed_body.dig("preview_file", "@id")).to eq "http://localhost:3214/models/#{id}/model_files/#{preview_file.to_param}"
        end
      end

      response "400", "The request structure was incorrect" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "422", "Update failed due to invalid data" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) { {"spdx:license" => {"licenseId" => "Ceci n'est pas un License"}} }

        run_test! do
          expect(response.parsed_body["license"]).to include("is not a valid license")
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

    delete "Remove an entire model" do
      tags "Models"
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
end
