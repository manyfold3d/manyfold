require "rails_helper"

RSpec.describe PrintHost do
  describe "creating valid objects" do
    let(:attributes) { attributes_for(:print_host) }

    it "can be created with valid data" do
      expect(described_class.create(attributes)).to be_valid
    end

    it "requires a name" do
      expect(described_class.create(attributes.except(:name))).not_to be_valid
    end

    it "requires an endpoint" do
      expect(described_class.create(attributes.except(:endpoint))).not_to be_valid
    end

    it "requires a protocol" do
      expect(described_class.create(attributes.except(:protocol))).not_to be_valid
    end

    it "requires a VALID protocol" do
      expect(described_class.create(attributes.merge(protocol: :nope))).not_to be_valid
    end
  end

  context "with a valid print host" do
    let(:print_host) { create(:print_host) }

    it "can list input types" do
      expect(print_host.input_types.map(&:to_s)).to eq ["text/x-gcode"]
    end
  end
end
