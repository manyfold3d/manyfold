# spec/requests/blogs_spec.rb
require "swagger_helper"

describe "oEmbed" do # rubocop:disable RSpec/EmptyExampleGroup, RSpec/DescribeClass
  path "/oembed" do
    get "generic oEmbed API endpoint" do
      tags "oEmbed"
      parameter name: :url, in: :query, type: :string, required: true
      parameter name: :maxwidth, in: :query, type: :integer, required: false
      parameter name: :maxheight, in: :query, type: :integer, required: false

      response "303", "Redirect to oembed version of the provided URL" do
        let(:url) { "http://www.example.com/models/abc123" }
        let(:maxwidth) { 256 }
        let(:maxheight) { 256 }

        run_test! do |response|
          expect(response).to redirect_to "http://www.example.com/models/abc123.oembed?maxheight=256&maxwidth=256"
        end
      end
    end
  end
end
