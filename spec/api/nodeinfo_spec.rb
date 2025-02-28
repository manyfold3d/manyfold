# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "Nodeinfo" do
  path "/.well-known/nodeinfo" do
    get "Get nodeinfo URL" do
      tags "Nodeinfo"
      produces "application/json"

      response "200", "blog found" do
        schema type: :object,
          properties: {
            links: {type: :array}
          },
          required: ["links"]

        run_test!
      end
    end
  end

  path "/nodeinfo/2.0" do
    get "Get nodeinfo" do
      tags "Nodeinfo"
      produces "application/json"

      response "200", "node info" do
        schema type: :object,
          properties: {
            version: {type: :string},
            protocols: {type: :array},
            services: {type: :object},
            openRegistrations: {type: :coolean}
          },
          required: ["version", "protocols", "services", "openRegistrations"]

        run_test!
      end
    end
  end
end
