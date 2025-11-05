# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "Creators", :after_first_run, :multiuser do # rubocop:disable RSpec/EmptyExampleGroup
  path "/creators" do
    get "A list of creators" do
      before do
        create_list(:creator, 9)
        create_list(:creator, 3, :public)
      end

      tags "Creators"
      produces Mime[:manyfold_api_v0].to_s
      parameter name: :page, in: :query, type: :integer, example: 1, description: "Specify which page of results to retrieve.", required: false
      parameter name: :order, in: :query, type: :string, enum: ["name", "recent", "updated"], description: "Specify order of results; either by name, creation time, or updated time", example: "name", required: false
      security [client_credentials: ["public", "read"]]

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

    post "Create a creator" do
      tags "Creators"
      consumes Mime[:manyfold_api_v0].to_s
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["write"]]
      parameter name: :body, in: :body, schema: ManyfoldApi::V0::CreatorDeserializer.schema_ref

      response "201", "Creator created" do
        schema ManyfoldApi::V0::CreatorSerializer.schema_ref
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) { {"name" => "Bruce Wayne"} }

        run_test! "produces valid linked data" do # rubocop:todo RSpec/MultipleExpectations
          # Tests are currently combined because database doesn't seem to clear between run_test! runs
          # Check JSON-LD
          graph = RDF::Graph.new << JSON::LD::API.toRdf(response.parsed_body)
          expect(graph).to be_valid
          # Check attributes
          expect(response.parsed_body["name"]).to eq "Bruce Wayne"
        end
      end

      response "400", "The request structure was incorrect" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "422", "Creation failed due to invalid data" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) { {"name" => create(:creator).name} }

        run_test! do
          expect(response.parsed_body["name"]).to include("has already been taken")
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

  path "/creators/{id}" do
    parameter name: :id, in: :path, type: :string, required: true, example: "abc123"

    let(:user) { create(:user) }
    let(:creator) { create(:creator) }
    let(:id) { creator.to_param }

    get "Details of a single creator" do
      tags "Creators"
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["public", "read"]]

      response "200", "Success" do
        schema ManyfoldApi::V0::CreatorSerializer.schema_ref
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

    patch "Update a creator" do
      tags "Creators"
      consumes Mime[:manyfold_api_v0].to_s
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["write"]]
      parameter name: :body, in: :body, schema: ManyfoldApi::V0::CreatorDeserializer.schema_ref

      response "200", "Creator updated" do
        schema ManyfoldApi::V0::CreatorSerializer.schema_ref
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) { {"name" => "Bruce Wayne"} }

        run_test! "produces valid linked data" do
          graph = RDF::Graph.new << JSON::LD::API.toRdf(response.parsed_body)
          expect(graph).to be_valid
        end

        run_test! do
          expect(response.parsed_body["name"]).to eq "Bruce Wayne"
        end
      end

      response "400", "The request structure was incorrect" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "422", "Creation failed due to invalid data" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) { {"name" => create(:creator).name} }

        run_test! do
          expect(response.parsed_body["name"]).to include("has already been taken")
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

    delete "Remove a creator" do
      tags "Creators"
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
