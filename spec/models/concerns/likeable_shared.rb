shared_examples "Likeable" do
  let(:user) { create :user }
  let(:thing) { create(described_class.to_s.underscore.to_sym) }

  it "changes like count when added to a list" do
    expect{user.liked_list.models << thing}.to change(thing, :like_count).by(1)
  end

  context "with federation", :federated do
    let(:actor) { create :actor, :distant }

    it "includes remote Like activities in count" do
      expect{
        Federails::Activity.create action: "Like", entity: thing, actor: actor
      }.to change(thing, :like_count).by(1)
    end

    it "includes Likes on system comments in count" do
      comment = create :comment, commentable: thing, system: true, commenter: thing
      expect{
        Federails::Activity.create action: "Like", entity: comment, actor: actor
      }.to change(thing, :like_count).by(1)
    end

    it "ignores Likes on non-system comments in count" do
      comment = create :comment, commentable: thing, system: false, commenter: thing
      expect{
        Federails::Activity.create action: "Like", entity: comment, actor: actor
      }.not_to change(thing, :like_count)
    end

    it "ignores local Like activities in count" do
      expect{
        Federails::Activity.create action: "Like", entity: thing, actor: user.federails_actor
      }.not_to change(thing, :like_count)
    end
  end
end
