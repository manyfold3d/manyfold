shared_examples "Caber::Subject" do
  let(:caber_subject) { create(described_class.to_s.underscore.to_sym) }

  it "has caber relations" do
    expect(caber_subject.class).to respond_to :can_have_permissions_on
  end

  context "with view permissions on an object" do
    let(:model) { create(:model) }

    before do
      model.grant_permission_to("view", caber_subject)
    end

    it "has permission in list" do
      expect(caber_subject.caber_relations.length).to be 1
    end

    it "has permission on object" do
      expect(caber_subject.has_permission_on?("view", model)).to be true
    end
  end
end
