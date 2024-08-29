shared_examples "Caber::Subject" do
  let(:caber_subject) { create(described_class.to_s.underscore.to_sym) }

  it "has caber relations" do
    expect(caber_subject.class).to respond_to :can_have_permissions_on
  end
end
