require "rails_helper"

#      collections GET    /collections(.:format)                                                  collections#index
#                  POST   /collections(.:format)                                                  collections#create
#   new_collection GET    /collections/new(.:format)                                              collections#new
#  edit_collection GET    /collections/:id/edit(.:format)                                         collections#edit
#       collection GET    /collections/:id(.:format)                                              collections#show
#                  PATCH  /collections/:id(.:format)                                              collections#update
#                  PUT    /collections/:id(.:format)                                              collections#update
#                  DELETE /collections/:id(.:format)                                              collections#destroy

RSpec.describe "Collections" do
  let(:collection) { create(:collection) }

  context "when signed out" do
    it "needs testing when multiuser is enabled"
  end

  context "when signed in" do
    before do
      build_list(:collection, 13) do |collection|
        collection.save! # See https://dev.to/hernamvel/the-optimal-way-to-create-a-set-of-records-with-factorybot-createlist-factorybot-buildlist-1j64
        create_list(:link, 1, linkable: collection)
        create_list(:model, 1, collection: collection)
      end
    end

    describe "GET /collections" do
      it "returns paginated collections", :as_viewer do # rubocop:todo RSpec/MultipleExpectations
        get "/collections?page=2"
        expect(response).to have_http_status(:success)
        expect(response.body).to match(/pagination/)
      end
    end

    describe "POST /collections" do
      it "creates a new collection", :as_contributor do
        post "/collections", params: {collection: {name: "newname"}}
        expect(response).to redirect_to("/collections")
      end
    end

    describe "GET /collections/new", :as_contributor do
      it "Shows the new collection form" do
        get "/collections/new"
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /collections/:id/edit", :as_editor do
      it "Shows the new collection form" do
        get "/collections/#{collection.id}/edit"
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /collections/:id", :as_viewer do
      it "Redirects to a list of models with that collection" do
        get "/collections/#{collection.id}"
        expect(response).to redirect_to("/models?collection=#{collection.id}")
      end
    end

    describe "PATCH /collections/:id", :as_editor do
      it "saves details" do
        patch "/collections/#{collection.id}", params: {collection: {name: "newname"}}
        expect(response).to redirect_to("/collections")
      end
    end

    describe "DELETE /collections/:id", :as_editor do
      it "removes collection" do
        delete "/collections/#{collection.id}"
        expect(response).to redirect_to("/collections")
      end
    end
  end
end
