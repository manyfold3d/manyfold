shared_examples "Listable" do
  let(:thing) { create(described_class.to_s.underscore.to_sym) }
  let(:user) { create(:user) }

  before do
    user.list(thing, :printed)
  end

  it "shows as listed" do
    expect(user.listed?(thing, :printed)).to be true
  end

  it "can access listers" do
    expect(thing.listers(:printed)).to contain_exactly(user)
  end
end
