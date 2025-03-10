# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "Models" do # rubocop:disable RSpec/EmptyExampleGroup
  path "/models/{id}.oembed" do
    before do |example|
      submit_request(example.metadata)
    end

    get "oEmbed response for Models" do
      tags "oEmbed"
      produces "application/json+oembed"
      parameter name: :id, in: :path, type: :string
      parameter name: :maxwidth, in: :query, type: :integer, required: false
      parameter name: :maxheight, in: :query, type: :integer, required: false

      response "200", "Success" do
        schema oneOf:
          [
            {"$ref" => "#/components/schemas/oembed_rich"},
            {"$ref" => "#/components/schemas/oembed_photo"},
            {"$ref" => "#/components/schemas/oembed_video"},
            {"$ref" => "#/components/schemas/oembed_link"}
          ],
          discriminator: {
            propertyName: :type,
            mapping: {
              rich: "#/components/schemas/oembed_rich",
              photo: "#/components/schemas/oembed_photo",
              video: "#/components/schemas/oembed_video",
              link: "#/components/schemas/oembed_link"
            }
          }

        let(:id) { create(:model, :public).to_param }

        it "returns a valid 201 response" do |example|
          assert_response_matches_metadata(example.metadata)
        end
      end

      response "401", "Unauthorized" do
        let(:id) { create(:model).to_param }
        run_test!
      end
    end
  end
end
