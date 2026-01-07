# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "Groups", :after_first_run, :multiuser do # rubocop:disable RSpec/EmptyExampleGroup
  let(:creator) { create(:creator) }
  let(:creator_id) { creator.to_param }

  before do
    create_list(:group, 5, creator: creator)
  end

  path "/creators/{creator_id}/groups" do
    parameter name: :creator_id, in: :path, type: :string, required: true, example: "abc123"
    parameter name: :page, in: :query, type: :integer, example: 1, description: "Specify which page of results to retrieve.", required: false

    get "A list of groups associated with a creator" do
      tags "Groups"
      produces Mime[:manyfold_api_v0].to_s
      security [client_credentials: ["read"]]

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
                  "@id": {type: :string, example: "/creators/abc123/groups/1", description: "The URL of the group"},
                  name: {type: :string, example: "Fred", description: "The human name of the group"}
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
  end
end
