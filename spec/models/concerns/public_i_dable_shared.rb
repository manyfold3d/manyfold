shared_examples "PublicIDable" do
  let!(:thing) { create(described_class.to_s.underscore.to_sym) }

  it "autogenerates a public ID upon creation" do
    expect(thing.public_id).to be_present
  end

  it "uses public IDs in URLs" do
    expect(thing.to_param).to eq thing.public_id
  end

  it "can find by public ID" do
    expect(described_class.find_param(thing.to_param)).to eq thing
  end
end
