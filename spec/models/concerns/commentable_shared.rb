shared_examples "Commentable" do
  subject(:target) { create(described_class.to_s.underscore.to_sym) }

  it "has comments" do
    expect(target).to respond_to :comments
  end
end
