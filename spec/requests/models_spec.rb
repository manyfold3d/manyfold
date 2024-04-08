require "rails_helper"

#  edit_library_model GET    /libraries/:library_id/models/:id/edit(.:format)                        models#edit
#       library_model GET    /libraries/:library_id/models/:id(.:format)                             models#show
#                     PATCH  /libraries/:library_id/models/:id(.:format)                             models#update
#                     PUT    /libraries/:library_id/models/:id(.:format)                             models#update
#                     DELETE /libraries/:library_id/models/:id(.:format)                             models#destroy
#         edit_models GET    /models/edit(.:format)                                                  models#bulk_edit
#       update_models PATCH  /models/update(.:format)                                                models#bulk_update
#              models GET    /models(.:format)                                                       models#index
# merge_library_model POST   /libraries/:library_id/models/:id/merge(.:format)                       models#merge
# scan_library_model  POST   /libraries/:library_id/models/:id/scan(.:format)                        models#scan

RSpec.describe "Models" do
  context "when signed out" do
    it "needs testing when multiuser is enabled"
  end

  context "when signed in" do
    let(:library) do
      l = create(:library)
      build_list(:model, 15, library: l) { |x| x.save! }
      l
    end
    let(:creator) { create(:creator) }

    describe "GET /libraries/:library_id/models/:id", :as_viewer do
      it "returns http success" do
        get "/libraries/#{library.id}/models/#{library.models.first.id}"
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /libraries/:library_id/models/:id/edit" do
      it "shows edit page for file", :as_editor do
        get "/libraries/#{library.id}/models/#{library.models.first.id}/edit"
        expect(response).to have_http_status(:success)
      end

      it "is denied to non-editors", :as_contributor do
        expect { get "/libraries/#{library.id}/models/#{library.models.first.id}/edit" }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "PUT /libraries/:library_id/models/:id" do
      it "adds tags to a model", :as_editor do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
        put "/libraries/#{library.id}/models/#{library.models.first.id}", params: {model: {tag_list: ["a", "b", "c"]}}
        expect(response).to have_http_status(:redirect)
        tags = library.models.first.tag_list
        expect(tags.length).to eq 3
        expect(tags[0]).to eq "a"
        expect(tags[1]).to eq "b"
        expect(tags[2]).to eq "c"
      end

      it "removes tags from a model", :as_editor do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
        first = library.models.first
        first.tag_list = "a, b, c"
        first.save

        put "/libraries/#{library.id}/models/#{library.models.first.id}", params: {model: {tag_list: ["a", "b"]}}
        expect(response).to have_http_status(:redirect)
        tags = library.models.first.tag_list
        expect(tags.length).to eq 2
        expect(tags[0]).to eq "a"
        expect(tags[1]).to eq "b"
      end

      it "both adds and removes tags from a model", :as_editor do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
        first = library.models.first
        first.tag_list = "a, b, c"
        first.save

        put "/libraries/#{library.id}/models/#{library.models.first.id}", params: {model: {tag_list: ["a", "b", "d"]}}
        expect(response).to have_http_status(:redirect)
        tags = library.models.first.tag_list
        expect(tags.length).to eq 3
        expect(tags[0]).to eq "a"
        expect(tags[1]).to eq "b"
        expect(tags[2]).to eq "d"
      end

      it "is denied to non-editors", :as_contributor do
        expect { put "/libraries/#{library.id}/models/#{library.models.first.id}" }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "DELETE /libraries/:library_id/models/:id" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "redirects to model list after deletion", :as_editor do
        delete "/libraries/#{library.id}/models/#{library.models.first.id}"
        expect(response).to redirect_to("/libraries/#{library.id}")
      end

      it "is denied to non-editors", :as_contributor do
        expect { delete "/libraries/#{library.id}/models/#{library.models.first.id}" }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "GET /models/edit" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "shows bulk edit page", :as_editor do
        get "/models/edit"
        expect(response).to have_http_status(:success)
      end

      it "is denied to non-editors", :as_contributor do
        expect { get "/models/edit" }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "PATCH /models/edit" do
      it "updates models creator", :as_editor do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
        models = library.models.take(2)
        update = {}
        update[models[0].id] = 1
        update[models[1].id] = 1

        patch "/models/update", params: {models: update, creator_id: creator.id}

        expect(response).to have_http_status(:redirect)
        models.each { |model| model.reload }
        expect(models[0].creator_id).to eq creator.id
        expect(models[1].creator_id).to eq creator.id
      end

      it "adds tags to models", :as_editor do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
        update = {}
        library.models.take(2).each do |model|
          update[model.id] = 1
        end

        patch "/models/update", params: {models: update, add_tags: ["a", "b", "c"]}

        expect(response).to have_http_status(:redirect)
        library.models.take(2).each do |model|
          expect(model.tag_list).to eq ["a", "b", "c"]
        end
      end

      it "removes tags from models", :as_editor do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
        update = {}
        library.models.take(2).each do |model|
          model.tag_list = "a, b, c"
          model.save
          update[model.id] = 1
        end

        patch "/models/update", params: {models: update, remove_tags: ["a", "b"]}

        expect(response).to have_http_status(:redirect)
        library.models.take(2).each do |model|
          expect(model.tag_list).to eq ["c"]
        end
      end

      it "is denied to non-editors", :as_contributor do
        update = {}
        expect { patch "/models/update", params: {models: update, remove_tags: ["a", "b"]} }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "GET /models", :as_viewer do
      it "returns paginated models" do # rubocop:todo RSpec/MultipleExpectations
        get "/models?library=#{library.id}&page=2"
        expect(response).to have_http_status(:success)
        expect(response.body).to match(/pagination/)
      end
    end

    describe "POST /libraries/:library_id/models/:id/merge" do
      it "gives a bad request response if no merge parameter is provided", :as_editor do
        post "/libraries/#{library.id}/models/#{library.models.first.id}/merge"
        expect(response).to have_http_status(:bad_request)
      end

      it "is denied to non-editors", :as_contributor do
        expect { post "/libraries/#{library.id}/models/#{library.models.first.id}/merge" }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /libraries/:library_id/models/:id/scan" do
      it "schedules a scan job", :as_editor do
        expect { post "/libraries/#{library.id}/models/#{library.models.first.id}/scan" }.to(
          have_enqueued_job(Scan::CheckModelJob).with(library.models.first.id).once
        )
      end

      it "redirects back to model page", :as_contributor do
        post "/libraries/#{library.id}/models/#{library.models.first.id}/scan"
        expect(response).to redirect_to("/libraries/#{library.id}/models/#{library.models.first.id}")
      end

      it "is denied to non-contributors", :as_viewer do
        expect { post "/libraries/#{library.id}/models/#{library.models.first.id}/scan" }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
