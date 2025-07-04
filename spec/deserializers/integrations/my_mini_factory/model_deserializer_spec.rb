require "rails_helper"

RSpec.describe Integrations::MyMiniFactory::ModelDeserializer do
  let(:api_key) { ENV.fetch("MYMINIFACTORY_API_KEY", "abcd1234") }

  context "when creating from URI" do
    it "accepts object URIs" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/object/3d-print-example-1234", api_key: api_key)
      expect(deserializer).to be_valid
    end

    it "rejects non-object URIs" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example", api_key: api_key)
      expect(deserializer).not_to be_valid
    end

    it "extracts object ID" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/object/3d-print-example-1234", api_key: api_key)
      expect(deserializer.object_id).to eq "1234"
    end
  end
end
