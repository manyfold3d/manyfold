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
          :jsonld_context => {
            type: :array,
            items: {
              oneOf: [
                {type: :string},
                {type: :object}
              ]
            }
          },
          :oembed_link => {
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
          :oembed_photo => {
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
          :oembed_video => {
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
          :oembed_rich => {
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
          :spdxLicense => {
            type: :object,
            properties: {
              "@type": {type: :string, example: "spdx:License"},
              "@id": {type: :string, example: "http://spdx.org/licenses/MIT"},
              licenseId: {type: :string, example: "MIT"}
            },
            required: ["@type", "licenseId"]
          },
          ManyfoldApi::V0::LinkDeserializer.schema_ref_name => ManyfoldApi::V0::LinkDeserializer.schema,
          ManyfoldApi::V0::CollectionDeserializer.schema_ref_name => ManyfoldApi::V0::CollectionDeserializer.schema,
          ManyfoldApi::V0::CollectionSerializer.schema_ref_name => ManyfoldApi::V0::CollectionSerializer.schema,
          ManyfoldApi::V0::CreatorDeserializer.schema_ref_name => ManyfoldApi::V0::CreatorDeserializer.schema,
          ManyfoldApi::V0::CreatorSerializer.schema_ref_name => ManyfoldApi::V0::CreatorSerializer.schema,
          ManyfoldApi::V0::GroupDeserializer.schema_ref_name => ManyfoldApi::V0::GroupDeserializer.schema,
          ManyfoldApi::V0::GroupSerializer.schema_ref_name => ManyfoldApi::V0::GroupSerializer.schema,
          ManyfoldApi::V0::ModelDeserializer.schema_ref_name => ManyfoldApi::V0::ModelDeserializer.schema,
          ManyfoldApi::V0::ModelSerializer.schema_ref_name => ManyfoldApi::V0::ModelSerializer.schema,
          ManyfoldApi::V0::ModelFileDeserializer.schema_ref_name => ManyfoldApi::V0::ModelFileDeserializer.schema,
          ManyfoldApi::V0::ModelFileSerializer.schema_ref_name => ManyfoldApi::V0::ModelFileSerializer.schema,
          ManyfoldApi::V0::UploadedFileDeserializer.schema_ref_name => ManyfoldApi::V0::UploadedFileDeserializer.schema,
          ManyfoldApi::V0::UploadedModelDeserializer.schema_ref_name => ManyfoldApi::V0::UploadedModelDeserializer.schema
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
