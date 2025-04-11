# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join("app/api").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    "v0/openapi.json" => {
      openapi: "3.0.1",
      info: {
        title: "Manyfold API",
        version: "0",
        description: <<~EOF
          This document describes the REST API for this [Manyfold](https://manyfold.app) instance.

          Warning! This API...

          * ... is not complete! Functionality is limited for now, but future releases will add more capabilities.
          * ... is not yet at v1! It's subject to breaking changes at any time.
          * ... is only valid for this host! Other Manyfold instances running different software versions may expose a different set of API functionality.
        EOF
      },
      paths: {},
      servers: [
        {
          url: "https://try.manyfold.app"
        }
      ],
      components: {
        securitySchemes: {
          client_credentials: {
            type: :oauth2,
            description: "Authentication with the OAuth2 Client Credentials grant flow. You can generate client app credentials at /oauth/applications.",
            flows: {
              clientCredentials: {
                tokenUrl: "/oauth/token",
                scopes: {
                  public: "read public data accessible without logging in",
                  read: "read data accessible to the OAuth application's owner",
                  write: "create or change data that the OAuth application's owner has appropriate permissions for",
                  delete: "remove data that the OAuth application's owner has appropriate permissions for"
                }
              }
            }
          }
        },
        schemas: {
          jsonld_context: {
            type: :array,
            items: {
              oneOf: [
                {type: :string},
                {type: :object}
              ]
            }
          },
          oembed_link: {
            type: :object,
            properties: {
              version: {type: :string, example: "1.0"},
              type: {type: :string, example: "link"},
              title: {type: :string, example: "Model Title"},
              author_name: {type: :string, example: "Creator Name"},
              author_url: {type: :string, example: "https://example.com/creators/bob"},
              provider_name: {type: :string, example: "Manyfold"},
              provider_url: {type: :string, example: "https://example.com"},
              cache_age: {type: :integer, example: 86400}
            },
            required: [:version, :type]
          },
          oembed_photo: {
            type: :object,
            properties: {
              version: {type: :string, example: "1.0"},
              type: {type: :string, example: "photo"},
              url: {type: :string, example: "https://example.com/models/123/model_files/456.png"},
              width: {type: :integer, example: "256"},
              height: {type: :integer, example: "256"},
              title: {type: :string, example: "Model Title"},
              author_name: {type: :string, example: "Creator Name"},
              author_url: {type: :string, example: "https://example.com/creators/bob"},
              provider_name: {type: :string, example: "Manyfold"},
              provider_url: {type: :string, example: "https://example.com"},
              cache_age: {type: :integer, example: 86400}
            },
            required: [:version, :type, :url, :width, :height]
          },
          oembed_video: {
            type: :object,
            properties: {
              version: {type: :string, example: "1.0"},
              type: {type: :string, example: "video"},
              html: {type: :string, example: "<iframe>...</iframe>"},
              width: {type: :integer, example: "256"},
              height: {type: :integer, example: "256"},
              title: {type: :string, example: "Model Title"},
              author_name: {type: :string, example: "Creator Name"},
              author_url: {type: :string, example: "https://example.com/creators/bob"},
              provider_name: {type: :string, example: "Manyfold"},
              provider_url: {type: :string, example: "https://example.com"},
              cache_age: {type: :integer, example: 86400}
            },
            required: [:version, :type, :html, :width, :height]
          },
          oembed_rich: {
            type: :object,
            properties: {
              version: {type: :string, example: "1.0"},
              type: {type: :string, example: "rich"},
              html: {type: :string, example: "<iframe>...</iframe>"},
              width: {type: :integer, example: "256"},
              height: {type: :integer, example: "256"},
              title: {type: :string, example: "Model Title"},
              author_name: {type: :string, example: "Creator Name"},
              author_url: {type: :string, example: "https://example.com/creators/bob"},
              provider_name: {type: :string, example: "Manyfold"},
              provider_url: {type: :string, example: "https://example.com"},
              cache_age: {type: :integer, example: 86400}
            },
            required: [:version, :type, :html, :width, :height]
          },
          spdxLicense: {
            type: :object,
            properties: {
              "@type": {type: :string, example: "spdx:License"},
              "@id": {type: :string, example: "http://spdx.org/licenses/MIT"},
              licenseId: {type: :string, example: "MIT"}
            },
            required: ["@type", "licenseId"]
          },
          collection_request: {
            type: :object,
            properties: {
              name: {type: :string, example: "My Favourites"},
              description: {type: :string, example: "This is my collection of favourite things"}
            },
            required: ["name"]
          },
          collection_response: {
            type: :object,
            properties: {
              "@context": {"$ref" => "#/components/schemas/jsonld_context"},
              "@id": {type: :string, example: "https://example.com/collections/abc123"},
              "@type": {type: :string, example: "Collection"},
              name: {type: :string, example: "Interesting Things"},
              description: {type: :string, example: "Lorem ipsum dolor sit amet...", description: "A longer description for the collection. Can contain Markdown syntax."},
              creator: {
                type: :object,
                properties: {
                  "@id": {type: :string, example: "https://example.com/creators/abc123"},
                  "@type": {type: :string, example: "Organization"}
                }
              }
            },
            required: ["@context", "@id", "@type", "name"]
          },
          creator_request: {
            type: :object,
            properties: {
              name: {type: :string, example: "Bruce Wayne"},
              description: {type: :string, example: "Lorem ipsum dolor sit amet..."}
            },
            required: ["name"]
          },
          creator_response: {
            type: :object,
            properties: {
              "@context": {"$ref" => "#/components/schemas/jsonld_context"},
              "@id": {type: :string, example: "https://example.com/creators/abc123"},
              "@type": {type: :string, example: "Organization"},
              name: {type: :string, example: "Bruce Wayne"},
              description: {type: :string, example: "Lorem ipsum dolor sit amet...", description: "A longer description for the creator. Can contain Markdown syntax."}
            },
            required: ["@context", "@id", "@type", "name"]
          },
          model_request: {
            type: :object,
            properties: {
              name: {type: :string, example: "Batmobile"},
              description: {type: :string, example: "Lorem ipsum dolor sit amet..."}
            }
          },
          model_response: {
            type: :object,
            properties: {
              "@context": {"$ref" => "#/components/schemas/jsonld_context"},
              "@id": {type: :string, example: "https://example.com/models/abc123"},
              "@type": {type: :string, example: "3DModel"},
              name: {type: :string, example: "3D Benchy"},
              description: {type: :string, example: "Lorem ipsum dolor sit amet...", description: "A longer description for the model. Can contain Markdown syntax."},
              hasPart: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    "@id": {type: :string, example: "https://example.com/models/abc123/model_files/def456"},
                    "@type": {type: :string, example: "3DModel"},
                    name: {type: :string, example: "Benchy"},
                    encodingFormat: {type: :string, example: "model/stl"}
                  }
                },
                required: ["@id", "@type", "name", "encodingFormat"]
              },
              "spdx:license": {"$ref" => "#/components/schemas/spdxLicense"},
              isPartOf: {type: :object, properties: {
                "@id": {type: :string, example: "https://example.com/collections/abc123"},
                "@type": {type: :string, example: "Collection"}
              }},
              creator: {
                type: :object,
                properties: {
                  "@id": {type: :string, example: "https://example.com/creators/abc123"},
                  "@type": {type: :string, example: "Organization"}
                }
              },
              keywords: {
                type: :array,
                items: {
                  type: :string,
                  example: "tag"
                }
              }
            },
            required: ["@context", "@id", "@type", "name", "hasPart"]
          },
          model_file_request: {
            type: :object,
            properties: {
              filename: {type: :string, example: "model.stl"},
              description: {type: :string, example: "Lorem ipsum dolor sit amet..."}
            }
          },
          model_file_response: {
            type: :object,
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
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :json

  config.openapi_no_additional_properties = true
end
