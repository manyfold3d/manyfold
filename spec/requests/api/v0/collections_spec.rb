# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "Collections", :after_first_run, :multiuser do # rubocop:disable RSpec/EmptyExampleGroup
  path "/collections" do
    get "A list of collections" do
      before do
        create_list(:collection, 9)
        create_list(:collection, 3, :public)
      end

      tags "Collections"
      produces Mime[:manyfold_api_v0].to_s
      parameter name: :page, in: :query, type: :integer, example: 1, description: "Specify which page of results to retrieve.", required: false
      parameter name: :order, in: :query, type: :string, enum: ["name", "recent", "updated"], description: "Specify order of results; either by name, creation time, or updated time", example: "name", required: false
      security [client_credentials: ["public", "read"]]

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

        context "with public scope" do
          let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "public").plaintext_token}" } # rubocop:disable RSpec/VariableName

          run_test! "produces valid linked data" do
            graph = RDF::Graph.new << JSON::LD::API.toRdf(response.parsed_body)
            expect(graph).to be_valid
          end

          run_test! do
            expect(response.parsed_body["totalItems"]).to eq 3
          end
        end

        context "with read scope" do
          let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "read").plaintext_token}" } # rubocop:disable RSpec/VariableName

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

    post "Create a new collection" do
      tags "Collections"
      consumes Mime[:manyfold_api_v0].to_s
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["write"]]
      parameter name: :body, in: :body, schema: ManyfoldApi::V0::CollectionDeserializer.schema_ref

      response "201", "Collection created" do
        schema ManyfoldApi::V0::CollectionSerializer.schema_ref
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) { {"name" => "My Favourites"} }

        run_test! "produces valid linked data" do # rubocop:todo RSpec/MultipleExpectations
          # Tests are currently combined because database doesn't seem to clear between run_test! runs
          # Check JSON-LD
          graph = RDF::Graph.new << JSON::LD::API.toRdf(response.parsed_body)
          expect(graph).to be_valid
          # Check attributes
          expect(response.parsed_body["name"]).to eq "My Favourites"
        end
      end

      response "400", "The request structure was incorrect" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "422", "Creation failed due to invalid data" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) { {"name" => create(:collection).name} }

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

  path "/collections/{id}" do
    parameter name: :id, in: :path, type: :string, required: true, example: "abc123"
    let(:collection) { create(:collection, creator: create(:creator), collection: create(:collection)) }
    let(:id) { collection.to_param }

    get "Details of a single collection" do
      tags "Collections"
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["public", "read"]]

      response "200", "Success" do
        schema ManyfoldApi::V0::CollectionSerializer.schema_ref
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "read").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test! "produces valid linked data" do
          graph = RDF::Graph.new << JSON::LD::API.toRdf(response.parsed_body)
          expect(graph).to be_valid
        end

        run_test! do
          expect(response.parsed_body["name"]).to eq collection.name
        end

        run_test! do
          expect(response.parsed_body["description"]).to eq collection.notes
        end

        run_test! do
          expect(response.parsed_body["caption"]).to eq collection.caption
        end

        run_test! do
          expect(response.parsed_body.dig("links", 0, "url")).to eq "http://example.com"
        end

        run_test! do
          expect(response.parsed_body.dig("creator", "@id")).to include collection.creator.to_param
        end

        run_test! do
          expect(response.parsed_body.dig("isPartOf", "@id")).to include collection.collection.to_param
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

    patch "Update a collection" do
      tags "Collections"
      consumes Mime[:manyfold_api_v0].to_s
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["write"]]
      parameter name: :body, in: :body, schema: ManyfoldApi::V0::CollectionDeserializer.schema_ref

      response "200", "Collection updated" do
        schema ManyfoldApi::V0::CollectionSerializer.schema_ref
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:creator) { create(:creator) }
        let(:parent_collection) { create(:collection) }
        let(:body) {
          {
            "name" => "My Favourites",
            "creator" => {"@id" => "http://localhost:3214/creators/#{creator.to_param}"},
            "isPartOf" => {"@id" => "http://localhost:3214/collections/#{parent_collection.to_param}"}
          }
        }

        run_test! "produces valid linked data" do
          graph = RDF::Graph.new << JSON::LD::API.toRdf(response.parsed_body)
          expect(graph).to be_valid
        end

        run_test! do
          expect(response.parsed_body["name"]).to eq "My Favourites"
        end

        run_test! do
          expect(response.parsed_body.dig("creator", "@id")).to eq "http://localhost:3214/creators/#{creator.to_param}"
        end

        run_test! do
          expect(response.parsed_body.dig("isPartOf", "@id")).to eq "http://localhost:3214/collections/#{parent_collection.to_param}"
        end
      end

      response "400", "The request structure was incorrect" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "422", "Creation failed due to invalid data" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) { {"name" => create(:collection).name} }

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

    delete "Remove a collection" do
      tags "Collections"
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
