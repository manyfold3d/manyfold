require "rails_helper"

RSpec.describe "Problems" do
  describe "GET /index" do
    before do
      create_list(:problem, 2, category: :inefficient)
      create_list(:problem, 3, category: :missing)
      sign_in User.first
    end

    it "returns success" do
      get "/problems/index"
      expect(response).to have_http_status(:success)
    end

    it "lists problems" do
      get "/problems/index"
      expect(assigns(:problems).length).to eq 5
    end

    context "with silenced problems" do
      before do
        u = User.first
        u.problem_settings["missing"] = "silent"
        u.save!
        sign_in u
      end

      it "doesn't show problems with silent severity" do
        get "/problems/index"
        expect(assigns(:problems).length).to eq 2
      end
    end
  end
end
