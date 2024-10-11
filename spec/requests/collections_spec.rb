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
      it "returns paginated collections", :as_member do # rubocop:todo RSpec/MultipleExpectations
        get "/collections?page=2"
        expect(response).to have_http_status(:success)
        expect(response.body).to match(/pagination/)
      end
    end

    describe "POST /collections" do
      it "creates a new collection and redirects to list", :as_contributor do
        post "/collections", params: {collection: {name: "newname"}}
        expect(response).to redirect_to("/collections")
      end

      it "creates a new collection owned by the current user", :as_contributor do # rubocop:disable RSpec/MultipleExpectations
        post "/collections", params: {collection: {name: "newname"}}
        object = Collection.find_by(name: "newname")
        expect(object.grants_permission_to?("own", controller.current_user)).to be true
      end

      it "creates a new collection and redirects to return location if set", :as_contributor do
        model = Model.first
        allow_any_instance_of(CollectionsController).to receive(:session).and_return({return_after_new: edit_model_path(model)}) # rubocop:disable RSpec/AnyInstance
        post "/collections", params: {collection: {name: "newname"}}
        expect(response).to redirect_to("/models/#{model.to_param}/edit?new_collection=#{Collection.find_by(name: "newname").to_param}")
      end

      it "denies member permission", :as_member do
        expect { post "/collections", params: {collection: {name: "newname"}} }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "GET /collections/new" do
      it "Shows the new collection form", :as_contributor do
        get "/collections/new"
        expect(response).to have_http_status(:success)
      end

      it "denies member permission", :as_member do
        expect { get "/collections/new" }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "GET /collections/:id/edit" do
      it "Shows the new collection form", :as_moderator do
        get "/collections/#{collection.to_param}/edit"
        expect(response).to have_http_status(:success)
      end

      it "is denied to non-moderators", :as_contributor do
        expect { get "/collections/#{collection.to_param}/edit" }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "GET /collections/:id", :as_member do
      it "Redirects to a list of models with that collection" do
        get "/collections/#{collection.to_param}"
        expect(response).to redirect_to("/models?collection=#{collection.public_id}")
      end
    end

    describe "PATCH /collections/:id" do
      it "saves details", :as_moderator do
        patch "/collections/#{collection.to_param}", params: {collection: {name: "newname"}}
        expect(response).to redirect_to("/collections")
      end
    end

    describe "DELETE /collections/:id" do
      it "removes collection", :as_moderator do
        delete "/collections/#{collection.to_param}"
        expect(response).to redirect_to("/collections")
      end

      it "is denied to non-moderators", :as_contributor do
        expect { delete "/collections/#{collection.to_param}" }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
