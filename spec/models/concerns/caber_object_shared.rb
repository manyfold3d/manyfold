shared_examples "Caber::Object" do
  let(:caber_object) { create(described_class.to_s.underscore.to_sym) }
  let!(:admin) { create(:admin) }
  let(:contributor) { create(:contributor) }

  it "has caber relations" do
    expect(caber_object.class).to respond_to :can_grant_permissions_to
  end

  it "is created with a default owner" do
    create(described_class.to_s.underscore.to_sym)
    expect(caber_object.grants_permission_to?("own", admin)).to be true
  end

  it "can be given an explicit owner at creation" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
    object = create(described_class.to_s.underscore.to_sym, described_class.caber_owner(contributor))
    expect(object.grants_permission_to?("own", contributor)).to be true
    expect(object.grants_permission_to?("own", admin)).to be false
  end
end
