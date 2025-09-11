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

  it "includes inherited indexable flag" do
    allow(SiteSettings).to receive(:default_indexable).and_return(false)
    object.update!(indexable: "inherit")
    expect(ap).to include({
      indexable: false
    })
  end

  it "includes explicit indexable flag" do
    allow(SiteSettings).to receive(:default_indexable).and_return(false)
    object.update!(indexable: "yes")
    expect(ap).to include({
      indexable: true
    })
  end

  it "includes discoverable flag set to same as indexable" do
    allow(SiteSettings).to receive(:default_indexable).and_return(false)
    object.update!(indexable: "yes")
    expect(ap).to include({
      discoverable: true
    })
  end
end
