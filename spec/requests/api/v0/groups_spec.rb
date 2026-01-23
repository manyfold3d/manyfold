# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "User Groups", :after_first_run, :multiuser do # rubocop:disable RSpec/EmptyExampleGroup
  let(:creator) { create(:creator) }
  let(:creator_id) { creator.to_param }

  before do
    create_list(:group, 5, creator: creator)
  end

  path "/creators/{creator_id}/groups" do
    parameter name: :creator_id, in: :path, type: :string, required: true, example: "abc123"

    get "A list of user groups associated with a creator" do
      tags "User Groups"
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["read"]]
      parameter name: :page, in: :query, type: :integer, example: 1, description: "Specify which page of results to retrieve.", required: false

      response "200", "Success" do
        schema type: :object,
          properties: {
            "@context": {"$ref" => "#/components/schemas/jsonld_context"},
            "@id": {type: :string, example: "https://example.com/creators"},
            "@type": {type: :string, example: "hydra:Collection"},
            totalItems: {type: :integer, example: 3},
            member: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  "@id": {type: :string, example: "/creators/abc123/groups/1", description: "The URL of the user group"},
                  name: {type: :string, example: "Patrons", description: "The human name of the user group"}
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

        context "with read scope" do
          let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "read").plaintext_token}" } # rubocop:disable RSpec/VariableName

          run_test! "produces valid linked data" do
            graph = RDF::Graph.new << JSON::LD::API.toRdf(response.parsed_body)
            expect(graph).to be_valid
          end

          run_test! do
            expect(response.parsed_body["totalItems"]).to eq 5
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

    post "Create a new user group" do
      tags "User Groups"
      consumes Mime[:manyfold_api_v0].to_s
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["write"]]
      parameter name: :body, in: :body, schema: ManyfoldApi::V0::GroupDeserializer.schema_ref

      response "201", "Group created" do
        schema ManyfoldApi::V0::GroupSerializer.schema_ref
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) { {"name" => "Patrons", "description" => "My subscribers"} }

        run_test! "produces valid linked data" do # rubocop:todo RSpec/MultipleExpectations
          # Tests are currently combined because database doesn't seem to clear between run_test! runs
          # Check JSON-LD
          graph = RDF::Graph.new << JSON::LD::API.toRdf(response.parsed_body)
          expect(graph).to be_valid
          # Check attributes
          expect(response.parsed_body["name"]).to eq "Patrons"
          expect(response.parsed_body["description"]).to eq "My subscribers"
        end
      end

      response "400", "The request structure was incorrect" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "422", "Creation failed due to invalid data" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) { {"name" => ""} }

        run_test! do
          expect(response.parsed_body["name"]).to include("can't be blank")
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

  path "/creators/{creator_id}/groups/{id}" do
    parameter name: :creator_id, in: :path, type: :string, required: true, example: "abc123"
    parameter name: :id, in: :path, type: :string, required: true, example: "1"

    let(:user) { create(:user) }
    let(:group) { create(:group, members: [member]) }
    let(:creator_id) { group.creator.to_param }
    let(:id) { group.to_param }
    let(:member) { create(:user) }

    get "Get details of a single user group" do
      tags "User Groups"
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["read"]]

      response "200", "Success" do
        schema ManyfoldApi::V0::GroupSerializer.schema_ref
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "read").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test! "produces valid linked data" do
          graph = RDF::Graph.new << JSON::LD::API.toRdf(response.parsed_body)
          expect(graph).to be_valid
        end

        run_test! "includes member list" do
          expect(response.parsed_body["members"]).to eq [member.username]
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

    patch "Update a user group" do
      tags "User Groups"
      consumes Mime[:manyfold_api_v0].to_s
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["write"]]
      parameter name: :body, in: :body, schema: ManyfoldApi::V0::GroupDeserializer.schema_ref

      let(:new_member) { create(:user) }
      let(:removed_member) { create(:user) }
      let(:group) { create(:group, members: [member, removed_member]) }

      response "200", "Group updated" do
        schema ManyfoldApi::V0::GroupSerializer.schema_ref
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) {
          {
            "name" => "Patrons",
            "description" => "My subscribers",
            "add_members" => [new_member.email, "non_existent_user"],
            "remove_members" => [removed_member.email, "non_existent_user"]
          }
        }

        # Separating these into different tests causes problems with test setup conflicting, and I
        # don't want to spend time run_test! esoterics right now.
        run_test! do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
          # run_test! "produces valid linked data" do
          graph = RDF::Graph.new << JSON::LD::API.toRdf(response.parsed_body)
          expect(graph).to be_valid
          # run_test! "updates basic data" do
          expect(response.parsed_body["name"]).to eq "Patrons"
          # run_test! "adds new members" do
          expect(response.parsed_body["members"]).to include new_member.username
          # run_test! "removes members" do
          expect(response.parsed_body["members"]).not_to include removed_member.username
          # run_test! "leaves other members intact" do
          expect(response.parsed_body["members"]).to include member.username
        end
      end

      response "400", "The request structure was incorrect" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "422", "Update failed due to invalid data" do
        let(:Authorization) { "Bearer #{create(:oauth_access_token, scopes: "write").plaintext_token}" } # rubocop:disable RSpec/VariableName
        let(:body) { {"name" => ""} }

        run_test! do
          expect(response.parsed_body["name"]).to include("can't be blank")
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

    delete "Remove a user group" do
      tags "User Groups"
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
