shared_examples "Caber::Object" do
  let(:caber_object) { create(described_class.to_s.underscore.to_sym) }

  it "has caber relations" do
    expect(caber_object.class).to respond_to :can_grant_permissions_to
  end
end
