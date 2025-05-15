require "rails_helper"

RSpec.describe SearchQuery do
  subject(:service) { described_class.new(["cat", "in", "the", "hat"]) }

  context "with a simple query" do
    context "when converting to ransack" do
      it "searches fields using OR" do
        expect(service.ransack_options[:m]).to eq "or"
      end

      it "searches for string contained in model name field" do
        expect(service.ransack_options[:name_cont]).to eq "cat in the hat"
      end

      it "searches for string contained in creator name field" do
        expect(service.ransack_options[:creator_name_cont]).to eq "cat in the hat"
      end

      it "searches for string contained in collection name field" do
        expect(service.ransack_options[:collection_name_cont]).to eq "cat in the hat"
      end

      it "searches for tag" do
        expect(service.ransack_options[:tags_name_in]).to eq "cat in the hat"
      end
    end
  end
end
