require "rails_helper"

RSpec.describe "Reports", :after_first_run, :multiuser do
  let(:reportable) { create(:model, :public) }

  context "when logged in", :as_member do
    describe "GET /" do
      it "shows new report page" do
        get "/models/#{reportable.to_param}/reports/new"
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /" do
      let(:params) { {report: {content: "illegal content"}} }

      it "accepts report" do
        post "/models/#{reportable.to_param}/reports", params: params
        expect(response).to have_http_status(:found)
      end

      it "creates a report" do
        expect { post "/models/#{reportable.to_param}/reports", params: params }.to change(Fedipub::Moderation::Report, :count).by(1)
      end
    end
  end

  context "when not logged in" do
    describe "GET /" do
      it "denies permission to report" do
        get "/models/#{reportable.to_param}/reports/new"
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST /" do
      let(:params) { {report: {content: "illegal content"}} }

      it "denies permission to report" do
        post "/models/#{reportable.to_param}/reports", params: params
        expect(response).to have_http_status(:forbidden)
      end

      it "doesn't create a report" do
        expect { post "/models/#{reportable.to_param}/reports", params: params }.not_to change(Fedipub::Moderation::Report, :count)
      end
    end
  end
end
