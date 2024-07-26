shared_examples "Listable" do
  it "can be added to lists" do
    thing = create(described_class.to_s.underscore.to_sym)
    user = create(:user)
    user.list(thing, :printed)
    expect(user.listed?(thing, :printed)).to be true
  end
end
