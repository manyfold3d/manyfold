shared_examples "Likeable" do
  let(:user) { create :user }
  let(:thing) { create(described_class.to_s.underscore.to_sym) }

  it "changes like count when added to a list" do
    expect{user.liked_list.models << thing}.to change(thing, :like_count).by(1)
  end
end
