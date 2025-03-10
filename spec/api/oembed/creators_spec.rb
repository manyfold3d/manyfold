# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "Creators" do # rubocop:disable RSpec/EmptyExampleGroup
  path "/creators/{id}.oembed" do
    before do |example|
      submit_request(example.metadata)
    end

    get "oEmbed response for Creators" do
      tags "oEmbed"
      produces "application/json+oembed"
      parameter name: :id, in: :path, type: :string
      parameter name: :maxwidth, in: :query, type: :integer, required: false
      parameter name: :maxheight, in: :query, type: :integer, required: false

      response "200", "Success" do
        schema "$ref" => "#/components/schemas/oembed_link"

        let(:id) { create(:creator, :public).to_param }

        it "returns a valid 201 response" do |example|
          assert_response_matches_metadata(example.metadata)
        end
      end

      response "401", "Unauthorized" do
        let(:id) { create(:creator).to_param }
        run_test!
      end
    end
  end
end
