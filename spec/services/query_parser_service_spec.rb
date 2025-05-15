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

  context "with a multiword query" do
    let(:query) { "cat in the hat" }

    it "produces a parse tree with a muliple terms" do # rubocop:disable RSpec/ExampleLength
      expect(service.parse(query)).to eq({
        query: [
          {term: "cat"},
          {term: "in"},
          {term: "the"},
          {term: "hat"}
        ]
      })
    end
  end

  context "with required terms" do
    let(:query) { "cat in the +hat" }

    it "includes plus operator on relevant term" do
      expect(service.parse(query)[:query]).to include({
        term: "hat",
        operator: "+"
      })
    end
  end

  context "with excluded terms" do
    let(:query) { "cat in the -hat" }

    it "includes minus operator on relevant term" do
      expect(service.parse(query)[:query]).to include({
        term: "hat",
        operator: "-"
      })
    end
  end

  context "with field prefixes" do
    let(:query) { "cat in the -tag:hat" }

    it "includes prefix and operator on relevant term" do
      expect(service.parse(query)[:query]).to include({
        term: "hat",
        operator: "-",
        prefix: "tag"
      })
    end
  end

  context "with quoted phrase, specific prefix and operator" do
    let(:query) { "-creator:\"cat in\" the hat" }

    it "includes quoted part as a single term" do
      expect(service.parse(query)[:query]).to include({
        term: "cat in",
        operator: "-",
        prefix: "creator"
      })
    end
  end

  context "with quoted phrase" do
    let(:query) { "\"cat in\" the hat" }

    it "includes quoted part as a single term" do
      expect(service.parse(query)[:query]).to include({
        term: "cat in"
      })
    end
  end

  context "when using non alphanumeric characters in terms" do
    it "allows apostrophes in terms" do
      expect(service.parse("Bob's Burgers")[:query]).to include({
        term: "Bob's"
      })
    end

    it "allows emoji in terms" do
      expect(service.parse("I ❤️ NY")[:query]).to include({
        term: "❤️"
      })
    end

    it "allows hyphenated words" do
      expect(service.parse("Miles Cholmondley-Warner")[:query]).to include({
        term: "Cholmondley-Warner"
      })
    end
  end
end
