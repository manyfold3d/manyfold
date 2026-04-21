require "rails_helper"

RSpec.describe "Federails::QuoteAuthorizations", :after_first_run, :federated, :multiuser do
  describe "GET /federation/quote_authorizations/:id" do
    it "returns not found with bad UUID" do
      get "/federation/quote_authorizations/#{SecureRandom.uuid}", headers: {accept: "application/activity+json"}
      expect(response).to have_http_status :not_found
    end

    describe "with a valid quoted object" do
      let(:model) { create(:model, :public) }
      let(:comment) { create(:comment, federails_actor: model.federails_actor, commentable: model) }
      let(:auth) {
        Federails::QuoteAuthorization.create(
          federails_actor: model.federails_actor,
          quoting_actor: create(:actor, :distant),
          interaction_target: comment,
          interacting_object_url: "https://example.org/statuses/1",
          quote_request_url: "https://example.org/quote_requests/1"
        )
      }
      let(:json) { response.parsed_body }

      before do
        get "/federation/quote_authorizations/#{auth.to_param}", headers: {accept: "application/activity+json"}
      end

      it "succeeds" do
        expect(response).to have_http_status :success
      end

      it "has a QuoteAuthorization type" do
        expect(json["type"]).to eq "QuoteAuthorization"
      end

      it "has an interactingObject" do
        expect(json["interactingObject"]).to be_present
      end

      it "has an interactionTarget" do
        expect(json["interactionTarget"]).to eq "http://localhost:3214/federation/published/comments/#{comment.public_id}"
      end
    end
  end
end
