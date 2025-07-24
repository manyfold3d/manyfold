require "rails_helper"

RSpec.describe Integrations::BaseDeserializer do
  let(:deserializer) {
    test_serializer_class = Class.new(described_class) do
      def canonicalize(uri)
        uri
      end
    end
    test_serializer_class.new(uri: "https://example.com")
  }

  it "matches existing creator by URL" do
    url = "https://www.myminifactory.com/users/Scan%20The%20World"
    creator = create(:creator, links_attributes: [{url: url}])
    expect(deserializer.send(:attempt_creator_match, links_attributes: [{url: url}])).to eq({creator: creator})
  end

  it "matches existing creator by slug" do
    creator = create(:creator)
    expect(deserializer.send(:attempt_creator_match, slug: creator.slug)).to eq({creator: creator})
  end

  it "matches existing creator by name" do
    creator = create(:creator)
    expect(deserializer.send(:attempt_creator_match, name: creator.name)).to eq({creator: creator})
  end

  it "adds attributes for new creator if missing" do
    expect(deserializer.send(:attempt_creator_match, name: "New Creator")[:creator_attributes]).to include(name: "New Creator")
  end
end
