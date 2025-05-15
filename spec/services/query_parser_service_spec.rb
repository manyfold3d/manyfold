require "rails_helper"

RSpec.describe QueryParserService do
  subject(:service) { described_class.new }

  context "with a simple query" do
    let(:query) { "cat" }

    it "produces a parse tree with a single term" do
      expect(service.parse(query)).to eq({
        query: [
          {term: "cat"}
        ]
      })
    end
  end
end
