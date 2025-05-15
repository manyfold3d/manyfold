require "rails_helper"

RSpec.describe RansackQueryTransformer do
  subject(:result) { described_class.new.apply(query) }

  context "with a simple query" do
    let(:query) { QueryParserService.new.parse("cat in the hat") }

    context "when converting to ransack" do
      it "searches fields using OR" do
        expect(result[:m]).to eq "or"
      end

      it "searches for string contained in model name field" do
        expect(result[:name_cont_any]).to eq %w[cat in the hat]
      end

      it "searches for string contained in creator name field" do
        expect(result[:creator_name_cont_any]).to eq %w[cat in the hat]
      end

      it "searches for string contained in collection name field" do
        expect(result[:collection_name_cont_any]).to eq %w[cat in the hat]
      end

      it "searches for tag" do
        expect(result[:tags_name_in]).to eq %w[cat in the hat]
      end
    end
  end

  context "with a quoted query" do
    let(:query) { QueryParserService.new.parse("cat in \"the hat\"") }

    context "when converting to ransack" do
      it "searches fields using OR" do
        expect(result[:m]).to eq "or"
      end

      it "treats quoted part as a single term" do
        expect(result[:name_cont_any]).to eq ["cat", "in", "the hat"]
      end
    end
  end
end
