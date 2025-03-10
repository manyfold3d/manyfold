# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "Creators", :multiuser do # rubocop:disable RSpec/EmptyExampleGroup
  before { create(:admin) }

  path "/creators/{id}.oembed" do
    get "oEmbed response for Creators" do
      tags "oEmbed"
      produces "application/json+oembed"
      parameter name: :id, in: :path, type: :string
      parameter name: :maxwidth, in: :query, type: :integer, required: false
      parameter name: :maxheight, in: :query, type: :integer, required: false

      response "200", "Success" do
        schema "$ref" => "#/components/schemas/oembed_link"

        let(:id) { create(:creator, :public).to_param }
        run_test!
      end

      response "404", "Not Found or Unauthorized" do
        let(:id) { create(:creator).to_param }
        run_test!
      end
    end
  end
end
