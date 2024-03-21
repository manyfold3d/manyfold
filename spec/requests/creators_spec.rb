require "rails_helper"

#     creators GET    /creators(.:format)                                                     creators#index
#              POST   /creators(.:format)                                                     creators#create
#  new_creator GET    /creators/new(.:format)                                                 creators#new
# edit_creator GET    /creators/:id/edit(.:format)                                            creators#edit
#      creator GET    /creators/:id(.:format)                                                 creators#show
#              PATCH  /creators/:id(.:format)                                                 creators#update
#              PUT    /creators/:id(.:format)                                                 creators#update
#              DELETE /creators/:id(.:format)                                                 creators#destroy

RSpec.describe "Creators" do
  let(:creator) { create(:creator) }

  context "when signed out" do
    it "needs testing when multiuser is enabled"
  end

  context "when signed in" do
    before do
      build_list(:creator, 13) do |creator|
        creator.save! # See https://dev.to/hernamvel/the-optimal-way-to-create-a-set-of-records-with-factorybot-createlist-factorybot-buildlist-1j64
        create_list(:link, 1, linkable: creator)
        create_list(:model, 1, creator: creator)
      end
    end

    describe "GET /creators" do
      it "returns paginated creators", :as_viewer do # rubocop:todo RSpec/MultipleExpectations
        get "/creators?page=2"
        expect(response).to have_http_status(:success)
        expect(response.body).to match(/pagination/)
      end
    end

    describe "POST /creators" do
      it "creates a new creator", :as_contributor do
        post "/creators", params: {creator: {name: "newname"}}
        expect(response).to redirect_to("/creators")
      end
    end

    describe "GET /creators/new", :as_contributor do
      it "Shows the new creator form" do
        get "/creators/new"
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /creators/:id/edit", :as_editor do
      it "Shows the new creator form" do
        get "/creators/#{creator.id}/edit"
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /creators/:id", :as_viewer do
      it "Redirects to a list of models with that creator" do
        get "/creators/#{creator.id}"
        expect(response).to redirect_to("/models?creator=#{creator.id}")
      end
    end

    describe "PATCH /creators/:id", :as_editor do
      it "saves details" do
        patch "/creators/#{creator.id}", params: {creator: {name: "newname"}}
        expect(response).to redirect_to("/creators/#{creator.id}")
      end
    end

    describe "DELETE /creators/:id", :as_editor do
      it "removes creator" do
        delete "/creators/#{creator.id}"
        expect(response).to redirect_to("/creators")
      end
    end
  end
end
