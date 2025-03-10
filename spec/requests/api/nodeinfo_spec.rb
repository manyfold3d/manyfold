# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "NodeInfo", :api do # rubocop:disable RSpec/EmptyExampleGroup
  path "/.well-known/nodeinfo" do
    get "Discovery URL for NodeInfo protocol" do
      tags "NodeInfo"
      produces "application/json; profile=\"http://nodeinfo.diaspora.software/ns/schema/2.0#\""

      response "200", "Success" do
        schema type: :object,
          properties: {
            links: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  rel: {type: :string, example: "https://nodeinfo.diaspora.software/ns/schema/2.0"},
                  href: {type: :string, example: "/nodeinfo/2.0", description: "The URL to the full NodeInfo document"}
                }
              }
            }
          },
          required: ["links"]

        run_test!
      end
    end
  end

  path "/nodeinfo/2.0" do
    get "Get server metadata in NodeInfo 2.0 format" do
      tags "NodeInfo"
      produces "application/json; profile=\"http://nodeinfo.diaspora.software/ns/schema/2.0#\""

      response "200", "Success" do
        schema type: :object,
          properties: {
            version: {type: :string, example: "2.0"},
            software: {
              type: :object,
              properties: {
                name: {type: :string, example: "Manyfold"},
                version: {type: :string, example: "v0.103.0"}
              }
            },
            protocols: {
              type: :array,
              items: {
                type: :string,
                example: "activitypub"
              }
            },
            services: {
              type: :object,
              properties: {
                inbound: {type: :array, items: {type: :string}, example: []},
                outbound: {type: :array, items: {type: :string}, example: []}
              }
            },
            openRegistrations: {type: :boolean},
            usage: {
              type: :object,
              properties: {
                users: {
                  type: :object,
                  properties: {
                    total: {type: :integer},
                    activeMonth: {type: :integer},
                    activeHalfyear: {type: :integer}
                  }
                }
              }
            },
            metadata: {type: :object}
          },
          required: ["version", "software", "protocols", "openRegistrations"]

        run_test!
      end
    end
  end
end
