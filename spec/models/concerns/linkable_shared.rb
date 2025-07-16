shared_examples "Linkable" do
  let!(:thing) { create(described_class.to_s.underscore.to_sym, links_attributes: [{url: "https://example.com"}]) }

  it "can find by link" do
    expect(described_class.linked_to("https://example.com").first).to eq thing
  end

  it "only matches exact link" do
    expect(described_class.linked_to("https://example.com/nope").exists?).to be false
  end
end
