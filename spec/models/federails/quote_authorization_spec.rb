require "rails_helper"

RSpec.describe Federails::QuoteAuthorization do
  let(:model) { create(:model, :public) }
  let(:comment) { create(:comment, federails_actor: model.federails_actor, commentable: model) }
  let(:auth) {
    described_class.create(
      federails_actor: model.federails_actor,
      quoting_actor: create(:actor, :distant),
      interaction_target: comment,
      interacting_object_url: "https://example.org/statuses/1",
      quote_request_url: "https://example.org/quote_requests/1"
    )
  }

  it "autogenerates a UUID" do
    expect(auth.uuid).to be_present
  end

  it "can be accepted" do
    expect { auth.accept! }.to change(auth.reload, :state).from(nil).to("accepted")
  end

  it "can be rejected" do
    expect { auth.reject! }.to change(auth.reload, :state).from(nil).to("rejected")
  end

  it "creates appropriate activity when accepting" do
    expect { auth.accept! }.to change(Federails::Activity.where(action: "Accept"), :count).by(1)
  end

  it "creates appropriate activity when rejecting" do
    expect { auth.reject! }.to change(Federails::Activity.where(action: "Reject"), :count).by(1)
  end
end
