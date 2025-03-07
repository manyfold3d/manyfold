shared_examples "GenericActivityPubSerializer" do
  it "includes caption in summary" do
    expect(ap[:summary]).to include object.caption
  end

  it "includes notes in content" do
    expect(ap[:content]).to include object.notes
  end

  it "includes links as attachments" do
    expect(ap[:attachment]).to include({type: "Link", href: "http://example.com"})
  end
end
