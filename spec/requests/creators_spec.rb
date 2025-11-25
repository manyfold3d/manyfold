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
  it_behaves_like "Permittable", Creator

  context "when signed out in multiuser mode", :after_first_run, :multiuser do
    context "with public creator" do
      let!(:creator) { create(:creator, :public) }

      describe "GET /creators" do
        it "includes indexing directive header" do
          allow(SiteSettings).to receive_messages(default_indexable: true, default_ai_indexable: false)
          get "/creators"
          expect(response.headers["X-Robots-Tag"]).to eq "noai noimageai"
        end

        it "includes indexing directive meta tag" do
          allow(SiteSettings).to receive_messages(default_indexable: true, default_ai_indexable: false)
          get "/creators"
          expect(response.body).to include %(<meta name="robots" content="noai noimageai">)
        end
      end

      describe "GET /creators/:id" do
        it "returns http success" do
          get "/creators/#{creator.to_param}"
          expect(response).to have_http_status(:success)
        end

        it "includes indexing directive header" do
          allow(SiteSettings).to receive_messages(default_indexable: true, default_ai_indexable: false)
          get "/creators/#{creator.to_param}"
          expect(response.headers["X-Robots-Tag"]).to eq "noai noimageai"
        end

        it "includes indexing directive meta tag" do
          allow(SiteSettings).to receive_messages(default_indexable: true, default_ai_indexable: false)
          get "/creators/#{creator.to_param}"
          expect(response.body).to include %(<meta name="robots" content="noai noimageai">)
        end
      end
    end

    context "with non-public creator" do
      let(:creator) { create(:creator) }

      describe "GET /creators/:id" do
        it "returns not found" do
          get "/creators/#{creator.to_param}"
          expect(response).to be_not_found
        end
      end
    end
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
      it "returns paginated creators", :as_member do # rubocop:todo RSpec/MultipleExpectations
        get "/creators?page=2"
        expect(response).to have_http_status(:success)
        expect(response.body).to match(/pagination/)
      end
    end

    describe "POST /creators" do
      it "creates a new creator and redirects to new item", :as_contributor do
        post "/creators", params: {creator: {name: "newname"}}
        expect(response).to redirect_to("/creators/#{Creator.last.to_param}")
      end

      it "creates a new creator owned by the current user", :as_contributor do # rubocop:disable RSpec/MultipleExpectations
        post "/creators", params: {creator: {name: "newname"}}
        object = Creator.find_by(name: "newname")
        expect(object.grants_permission_to?("own", controller.current_user)).to be true
      end

      it "creates a new creator and redirects to return location if set", :as_contributor do
        model = Model.first
        allow_any_instance_of(CreatorsController).to receive(:session).and_return({return_after_new: edit_model_path(model)}) # rubocop:disable RSpec/AnyInstance
        post "/creators", params: {creator: {name: "newname"}}
        expect(response).to redirect_to("/models/#{model.to_param}/edit?new_creator=#{Creator.find_by(name: "newname").to_param}")
      end

      it "denies member permission", :as_member do
        post "/creators", params: {creator: {name: "newname"}}
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "GET /creators/new" do
      before { get "/creators/new" }

      it "Shows the new creator form", :as_contributor do
        expect(response).to have_http_status(:success)
      end

      it "denies member permission", :as_member do
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "GET /creators/:id/edit" do
      let(:creator) { create(:creator) }

      before { get "/creators/#{creator.to_param}/edit" }

      it "Shows the new creator form", :as_moderator do
        expect(response).to have_http_status(:success)
      end

      it "is denied to non-moderators", :as_contributor do
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "GET /creators/:id", :as_member do
      let(:creator) { create(:creator) }

      it "Redirects to a list of models with that creator" do
        get "/creators/#{creator.to_param}"
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH /creators/:id" do
      let(:creator) { create(:creator) }

      before { patch "/creators/#{creator.to_param}", params: {creator: {slug: "newname"}} }

      it "saves details", :as_moderator do
        expect(response).to redirect_to("/creators/newname")
      end

      it "is denied to non-moderators", :as_contributor do
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "DELETE /creators/:id" do
      let(:creator) { create(:creator) }

      before { delete "/creators/#{creator.to_param}" }

      it "removes creator", :as_moderator do
        expect(response).to redirect_to("/creators")
      end

      it "is denied to non-moderators", :as_contributor do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
