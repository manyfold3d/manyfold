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
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :json

  config.openapi_all_properties_required = true
  config.openapi_no_additional_properties = true
end
