require "rails_helper"

RSpec.describe "Quote authorizations", :after_first_run, :federated, :multiuser do
  describe "GET /federation/approval_stamps/:id" do
    it "returns not found with bad UUID" do
      get "/federation/approval_stamps/#{SecureRandom.uuid}", headers: {accept: "application/activity+json"}
      expect(response).to have_http_status :not_found
    end

    describe "when accepting a quote request" do # rubocop:todo RSpec/MultipleMemoizedHelpers
      let(:model) { create(:model, :public) }
      let(:comment) { create(:comment, fedipub_actor: model.fedipub_actor, commentable: model) }
      let(:quoting_actor) { create(:actor, :distant) }
      let(:quote_request) do
        create(:activity,
          action: "QuoteRequest",
          actor: quoting_actor,
          entity: comment,
          instrument: "https://example.com/quoting_comment")
      end
      let(:accept_activity) { quote_request.accept_quote_request! }
      let(:json) { response.parsed_body }

      it "creates an Accept activity" do
        expect(accept_activity.action).to eq "Accept"
      end

      it "links request as object of Accept activity" do
        expect(accept_activity.entity).to eq quote_request
      end

      it "links approval stamp as result of Accept activity" do
        expect(accept_activity.result).to match(/http:\/\/localhost:3214\/federation\/approval_stamps\/.*/)
      end

      context "when fetching the approval stamp" do # rubocop:todo RSpec/MultipleMemoizedHelpers
        before do
          approval_path = accept_activity.result.gsub("http://localhost:3214", "")
          get approval_path, headers: {accept: "application/activity+json"}
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
          expect(json["interactionTarget"]).to eq comment.federated_url
        end
      end
    end
  end
end
