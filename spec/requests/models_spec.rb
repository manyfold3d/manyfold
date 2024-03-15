require "rails_helper"

#      library_models POST   /libraries/:library_id/models(.:format)                                 models#create
#   new_library_model GET    /libraries/:library_id/models/new(.:format)                             models#new
#  edit_library_model GET    /libraries/:library_id/models/:id/edit(.:format)                        models#edit
#       library_model GET    /libraries/:library_id/models/:id(.:format)                             models#show
#                     PATCH  /libraries/:library_id/models/:id(.:format)                             models#update
#                     PUT    /libraries/:library_id/models/:id(.:format)                             models#update
#                     DELETE /libraries/:library_id/models/:id(.:format)                             models#destroy
#         edit_models GET    /models/edit(.:format)                                                  models#bulk_edit
#       update_models PATCH  /models/update(.:format)                                                models#bulk_update
#              models GET    /models(.:format)                                                       models#index
# merge_library_model POST   /libraries/:library_id/models/:id/merge(.:format)                       models#merge

RSpec.describe "Models" do
  context "when signed out" do
    it "needs testing when multiuser is enabled"
  end

  context "when signed in" do
    before do
      sign_in create(:user)
    end

    let(:library) do
      l = create(:library)
      build_list(:model, 15, library: l) { |x| x.save! }
      l
    end
    let(:creator) { create(:creator) }

    describe "POST /libraries/:library_id/models/" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "needs testing"
    end

    describe "GET /libraries/:library_id/models/:id/new" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "needs testing"
    end

    describe "GET /libraries/:library_id/models/:id" do
      it "returns http success" do
        get "/libraries/#{library.id}/models/#{library.models.first.id}"
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /libraries/:library_id/models/:id/edit" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "needs testing"
    end

    describe "PUT /libraries/:library_id/models/:id" do
      it "adds tags to a model" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
        put "/libraries/#{library.id}/models/#{library.models.first.id}", params: {model: {tag_list: ["a", "b", "c"]}}
        expect(response).to have_http_status(:redirect)
        tags = library.models.first.tag_list
        expect(tags.length).to eq 3
        expect(tags[0]).to eq "a"
        expect(tags[1]).to eq "b"
        expect(tags[2]).to eq "c"
      end

      it "removes tags from a model" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
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

      it "both adds and removes tags from a model" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
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
    end

    describe "DELETE /libraries/:library_id/models/:id" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "needs testing"
    end

    describe "GET /models/edit" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "needs testing"
    end

    describe "PATCH /models/edit" do
      it "updates models creator" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
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

      update = {}
      it "adds tags to models" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
        library.models.take(2).each do |model|
          update[model.id] = 1
        end

        patch "/models/update", params: {models: update, add_tags: ["a", "b", "c"]}

        expect(response).to have_http_status(:redirect)
        library.models.take(2).each do |model|
          expect(model.tag_list).to eq ["a", "b", "c"]
        end
      end

      it "removes tags from models" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
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
    end

    describe "GET /models" do
      it "returns paginated models" do # rubocop:todo RSpec/MultipleExpectations
        get "/models?library=#{library.id}&page=2"
        expect(response).to have_http_status(:success)
        expect(response.body).to match(/pagination/)
      end
    end

    describe "POST /libraries/:library_id/models/:id/merge" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "needs testing"
    end
  end
end
