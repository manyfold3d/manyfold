require "rails_helper"

RSpec.describe Comment do
  let!(:model) { create(:model) }
  let!(:comment) { create(:comment, commenter: model, commentable: model) }

  it "has a federated_url method" do
    expect(comment.federated_url).to eq "http://localhost:3214/models/#{model.public_id}/comments/#{comment.public_id}"
  end
end
