shared_examples "GenericDeserializer" do
  it "sets name" do
    expect(output.name).to eq actor.name
  end

  it "sets slug from username" do
    expect(output.slug).to eq actor.username
  end

  it "sets links from attachments" do
    expect(output.links&.first&.url).to eql "https://example.org"
  end

  it "ignores non-link attachments" do
    expect(output.links.length).to be 1
  end

  it "sets caption from summary" do
    expect(output.caption).to eq actor.extensions["summary"]
  end

  it "sets notes from content" do
    expect(output.notes).to eq actor.extensions["content"]
  end
end
