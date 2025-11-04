require "rails_helper"

#    edit_model GET    /models/:id/edit(.:format)                        models#edit
#         model GET    /models/:id(.:format)                             models#show
#               PATCH  /models/:id(.:format)                             models#update
#               PUT    /models/:id(.:format)                             models#update
#               DELETE /models/:id(.:format)                             models#destroy
#   edit_models GET    /models/edit(.:format)                            models#bulk_edit
# update_models PATCH  /models/update(.:format)                          models#bulk_update
#        models GET    /models(.:format)                                 models#index
#     new_model GET    /models/new(.:format)                             models#new
#               POST   /models(.:format)                                 models#create
#  merge_models POST   /models/merge(.:format)                           models#merge
#   scan_model  POST   /models/:id/scan(.:format)                        models#scan

RSpec.describe "Models" do
  context "when signed out in multiuser mode", :after_first_run, :multiuser do
    context "with public model" do
      let!(:model) { create(:model, :public) }

      describe "GET /models" do
        it "includes indexing directive header" do
          allow(SiteSettings).to receive_messages(default_indexable: true, default_ai_indexable: false)
          get "/models"
          expect(response.headers["X-Robots-Tag"]).to eq "noai noimageai"
        end

        it "includes indexing directive meta tag" do
          allow(SiteSettings).to receive_messages(default_indexable: true, default_ai_indexable: false)
          get "/models"
          expect(response.body).to include %(<meta name="robots" content="noai noimageai">)
        end
      end

      describe "GET /models/:id" do
        it "returns http success" do
          get "/models/#{model.to_param}"
          expect(response).to have_http_status(:success)
        end

        it "includes indexing directive header" do
          allow(SiteSettings).to receive_messages(default_indexable: true, default_ai_indexable: false)
          get "/models/#{model.to_param}"
          expect(response.headers["X-Robots-Tag"]).to eq "noai noimageai"
        end

        it "includes indexing directive meta tag" do
          allow(SiteSettings).to receive_messages(default_indexable: true, default_ai_indexable: false)
          get "/models/#{model.to_param}"
          expect(response.body).to include %(<meta name="robots" content="noai noimageai">)
        end
      end
    end

    context "with non-public model" do
      let!(:model) { create(:model) }

      describe "GET /models/:id" do
        it "returns not found" do
          get "/models/#{model.to_param}"
          expect(response).to be_not_found
        end
      end
    end
  end

  [:multiuser, :singleuser].each do |mode|
    context "when signed in in #{mode} mode", mode do
      let!(:creator) { create(:creator) }
      let!(:collection) { create(:collection) }
      let!(:library) do
        l = create(:library)
        build_list(:model, 5, library: l) { |it| it.save! }
        build_list(:model, 5, library: l, creator: creator) { |it| it.save! }
        build_list(:model, 5, library: l, collection: collection) { |it| it.save! }
        build_list(:model, 5, library: l, creator: creator, collection: collection) { |it| it.save! }
        l
      end

      describe "GET /models/:id", :as_member do
        it "returns http success" do
          get "/models/#{library.models.first.to_param}"
          expect(response).to have_http_status(:success)
        end
      end

      describe "GET /models/:id/edit" do
        before { get "/models/#{library.models.first.to_param}/edit" }

        it "shows edit page for file", :as_moderator do
          expect(response).to have_http_status(:success)
        end

        it "sets returnable session param", :as_moderator do
          expect(session[:return_after_new]).to eq "/models/#{library.models.first.to_param}/edit"
        end

        it "is denied to non-moderators", :as_contributor do
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe "PUT /models/:id" do
        it "adds tags to a model", :as_moderator do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          put "/models/#{library.models.first.to_param}", params: {model: {tag_list: ["a", "b", "c"]}}
          expect(response).to have_http_status(:redirect)
          expect(library.models.first.tag_list).to include("a", "b", "c")
        end

        it "clears returnable session param", :as_moderator do
          put "/models/#{library.models.first.to_param}", params: {model: {tag_list: ["a", "b", "c"]}}
          expect(session[:return_after_new]).to be_nil
        end

        it "removes tags from a model", :as_moderator do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          first = library.models.first
          first.tag_list = "a, b, c"
          first.save

          put "/models/#{library.models.first.to_param}", params: {model: {tag_list: ["a", "b"]}}
          expect(response).to have_http_status(:redirect)
          first.reload
          tags = first.tag_list
          expect(tags.length).to eq 2
          expect(tags).to contain_exactly("a", "b")
        end

        it "both adds and removes tags from a model", :as_moderator do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          first = library.models.first
          first.tag_list = "a, b, c"
          first.save

          put "/models/#{library.models.first.to_param}", params: {model: {tag_list: ["a", "b", "d"]}}
          expect(response).to have_http_status(:redirect)
          first.reload
          tags = first.tag_list
          expect(tags.length).to eq 3
          expect(tags).to contain_exactly("a", "b", "d")
        end

        it "auto-publishes creator if being made public", :as_moderator do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          private_creator = create(:creator)
          private_model = create(:model, creator: private_creator)
          put "/models/#{private_model.to_param}", params: {
            model: {
              creator_id: private_creator.id,
              caber_relations_attributes: {"0" => {subject: "role::public", permission: "view"}}
            }
          }
          expect(response).to have_http_status(:redirect)
          expect(private_model.reload).to be_public
          expect(private_creator.reload).to be_public
        end

        it "is denied to non-moderators", :as_contributor do
          put "/models/#{library.models.first.to_param}"
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe "DELETE /models/:id" do # rubocop:todo RSpec/RepeatedExampleGroupBody
        before { delete "/models/#{library.models.first.to_param}" }

        it "redirects to model list after deletion", :as_moderator do
          expect(response).to redirect_to("/")
        end

        it "is denied to non-moderators", :as_contributor do
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe "GET /models/edit" do # rubocop:todo RSpec/RepeatedExampleGroupBody
        before { get edit_models_path }

        it "shows bulk edit page", :as_moderator do
          expect(response).to have_http_status(:success)
        end

        it "sets returnable session param", :as_moderator do
          expect(session[:return_after_new]).to eq "/models/edit"
        end

        it "is denied to non-moderators", :as_contributor do
          expect(response).to have_http_status(:forbidden)
        end

        context "with filters", :as_moderator do
          let(:tag) { create(:tag) }
          let!(:tagged_model) { create(:model, library: library, tag_list: [tag.name]) }

          it "shows filtered models" do
            get edit_models_path(tag: [tag.name])
            expect(response.body).to include(tagged_model.name)
          end

          it "doesn't show other models" do
            get edit_models_path(tag: [tag.name])
            library.models.each do |model|
              next if model == tagged_model
              expect(response.body).not_to include(model.name)
            end
          end
        end
      end

      describe "PATCH /models/update" do
        let(:model_params) {
          model_params = {}
          library.models.each do |model|
            model_params[model.to_param] = 1
          end
          model_params
        }

        it "updates models creator", :as_moderator do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          models = library.models.take(2)
          update = {}
          update[models[0].to_param] = 1
          update[models[1].to_param] = 1

          patch update_models_path, params: {models: update, creator_id: creator.id}

          expect(response).to have_http_status(:redirect)
          models.each { |model| model.reload }
          expect(models[0].creator_id).to eq creator.id
          expect(models[1].creator_id).to eq creator.id
        end

        it "adds tags to models", :as_moderator do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          patch update_models_path, params: {models: model_params, add_tags: ["a", "b", "c"]}

          expect(response).to have_http_status(:redirect)
          library.models.take(2).each do |model|
            expect(model.tag_list).to include("a", "b", "c")
          end
        end

        it "removes tags from models", :as_moderator do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
          library.models.take(2).each do |model|
            model.tag_list = "a, b, c"
            model.save
          end

          patch update_models_path, params: {models: model_params, remove_tags: ["a", "b"]}

          expect(response).to have_http_status(:redirect)
          expect(library.models.tagged_with("c").count).to eq 2
          expect(library.models.tagged_with("a").count).to eq 0
        end

        it "clears returnable session param", :as_moderator do
          patch update_models_path, params: {models: model_params, remove_tags: ["a", "b"]}
          expect(session[:return_after_new]).to be_nil
        end

        it "is denied to non-moderators", :as_contributor do
          update = {}
          library.models.take(2).each { |it| update[it.to_param] = 1 }
          patch update_models_path, params: {models: model_params, remove_tags: ["a", "b"]}
          expect(response).to have_http_status(:forbidden)
        end

        context "when updating all filtered models", :as_moderator do # rubocop:todo RSpec/MultipleMemoizedHelpers
          let(:tag) { create(:tag) }
          let!(:tagged_model) { create(:model, library: library, tag_list: [tag.name]) }
          let(:new_library) { create(:library) }

          let(:params) do
            {
              update_all: I18n.t("models.bulk_edit.update_all"),
              new_library_id: new_library.id,
              tag: [tag.name]
            }
          end

          it "updates all models matching the filter" do
            patch update_models_path, params: params

            library.models.each do |model|
              next if model == tagged_model
              expect(model.reload.library_id).to eq(library.id)
            end
          end
        end
      end

      describe "GET /models", :as_member do
        it "allows search queries" do
          get "/models?q=#{library.models.first.name}"
          expect(response).to have_http_status(:success)
        end

        it "allows tag filters" do
          m = library.models.first
          m.tag_list << "test"
          m.save
          get "/models?tag[]=test"
          expect(response).to have_http_status(:success)
        end

        it "allows link filters" do
          get "/models?link="
          expect(response).to have_http_status(:success)
        end

        it "returns paginated models" do # rubocop:todo RSpec/MultipleExpectations
          get "/models?library=#{library.to_param}&page=2"
          expect(response).to have_http_status(:success)
          expect(response.body).to match(/pagination/)
        end
      end

      describe "POST /models/merge" do
        context "with a target and models to merge into it", :as_moderator do # rubocop:todo RSpec/MultipleMemoizedHelpers
          let(:model_one) { create(:model) }
          let(:model_two) { create(:model) }
          let(:merge_post) {
            post "/models/merge", params: {
              target: model_one.to_param,
              models: [model_two.to_param]
            }
          }

          it "is denied if the user doesn't have update permission on the models", :as_contributor do
            merge_post
            expect(response).to have_http_status(:forbidden)
          end

          it "is denied if the user doesn't have update permission on the target"
        end

        context "without any models", :as_moderator do
          let(:model) { create(:model) }
          let(:merge_post) {
            post "/models/merge", params: {
              target: model.to_param
            }
          }

          it "gives a bad request response if no models are provided" do
            merge_post
            expect(response).to have_http_status(:bad_request)
          end
        end

        context "without a target", :as_moderator do # rubocop:todo RSpec/MultipleMemoizedHelpers
          let(:model_one) { create(:model) }
          let(:model_two) { create(:model) }
          let(:merge_post) {
            post "/models/merge", params: {
              models: [model_one.to_param, model_two.to_param]
            }
          }

          before { merge_post }

          it "redirects to the merge options page" do
            expect(response).to redirect_to("/models/merge?models%5B%5D=#{model_one.to_param}&models%5B%5D=#{model_two.to_param}")
          end
        end

        context "when merging to target model", :as_moderator do # rubocop:todo RSpec/MultipleMemoizedHelpers
          let(:model_one) { create(:model) }
          let(:model_two) { create(:model) }
          let(:merge_post) {
            post "/models/merge", params: {
              models: [model_one.to_param, model_two.to_param],
              target: model_one.to_param
            }
          }

          before { merge_post }

          it "redirects to the target model" do
            expect(response).to redirect_to("/models/#{model_one.to_param}")
          end
        end

        context "when merging to a completely new model", :as_moderator do # rubocop:todo RSpec/MultipleMemoizedHelpers
          let(:model_one) { create(:model) }
          let(:model_two) { create(:model) }
          let(:merge_post) {
            post "/models/merge", params: {
              models: [model_one.to_param, model_two.to_param],
              target: "==new=="
            }
          }

          before { merge_post }

          it "redirects to the new model" do
            new_model = Model.last
            expect(response).to redirect_to("/models/#{new_model.to_param}")
          end

          it "Uses the name of the first merged model as the new name" do
            new_model = Model.last
            expect(new_model.name).to eq model_one.name
          end
        end

        context "when merging to a common root", :as_moderator do # rubocop:todo RSpec/MultipleMemoizedHelpers
          let(:model_one) { create(:model, path: "common/model_one") }
          let(:model_two) { create(:model, path: "common/model_two", library: model_one.library) }
          let(:merge_post) {
            post "/models/merge", params: {
              models: [model_one.to_param, model_two.to_param],
              target: "==common_root=="
            }
          }

          before { merge_post }

          it "redirects to the new model" do
            new_model = Model.last
            expect(response).to redirect_to("/models/#{new_model.to_param}")
          end

          it "uses the common root folder as the new path" do
            new_model = Model.last
            expect(new_model.path).to eq "common"
          end

          it "uses the name of the common root folder as the new name" do
            new_model = Model.last
            expect(new_model.name).to eq "Common"
          end
        end

        context "with form-encoded data", :as_moderator do # rubocop:todo RSpec/MultipleMemoizedHelpers
          let(:model_one) { create(:model) }
          let(:model_two) { create(:model) }
          let(:merge_post) {
            post "/models/merge", params: {
              models: {
                model_one.to_param => "0",
                model_two.to_param => "1"
              }
            }
          }

          before { merge_post }

          it "extracts selected models from form" do
            expect(assigns(:models)).to include model_two
          end

          it "ignores unselected models" do
            expect(assigns(:models)).not_to include model_one
          end
        end
      end

      describe "GET /models/merge", :as_moderator do # rubocop:todo RSpec/MultipleMemoizedHelpers
        let(:model_one) { create(:model) }
        let(:model_two) { create(:model) }
        let(:configure_merge) {
          get "/models/merge", params: {
            models: [model_one.to_param, model_two.to_param]
          }
        }

        before { configure_merge }

        it "merge options page includes a form for choosing the target" do
          expect(response.body).to include(%(<form action="/models/merge" accept-charset="UTF-8" method="post">))
        end
      end

      describe "POST /models/:id/scan" do
        it "schedules a scan job", :as_moderator do
          expect { post "/models/#{library.models.first.to_param}/scan" }.to(
            have_enqueued_job(Scan::CheckModelJob).with(library.models.first.id).once
          )
        end

        it "redirects back to model page", :as_contributor do
          post "/models/#{library.models.first.to_param}/scan"
          expect(response).to redirect_to("/models/#{library.models.first.public_id}")
        end

        it "is denied to non-contributors", :as_member do
          post "/models/#{library.models.first.to_param}/scan"
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe "GET /models/new" do
        before { get "/models/new" }

        it "shows upload form", :as_contributor do
          expect(response).to have_http_status(:success)
        end

        it "sets returnable session param", :as_contributor do
          expect(session[:return_after_new]).to eq "/models/new"
        end

        it "denies member permission", :as_member do
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe "POST /models" do
        let(:creator) { create(:creator) }
        let(:collection) { create(:collection) }
        let(:post_models) {
          post "/models", params: {
            library: library.to_param,
            scan: "1",
            file: files,
            creator_id: creator.id,
            collection_id: collection.id,
            license: "MIT",
            sensitive: "1",
            permission_preset: "public",
            tag_list: ["tag1", "tag2"],
            name: "Only used for single model upload"
          }
        }

        context "with a single uncompressed file", :as_contributor do
          let(:files) {
            {
              "0" => {
                id: "upload_key",
                name: "test.stl"
              }
            }
          }

          it "enqueues processing job with all parameters" do # rubocop:disable RSpec/ExampleLength
            expect { post_models }
              .to have_enqueued_job(ProcessUploadedFileJob)
              .with(Library.first.id,
                [{
                  id: "upload_key",
                  storage: "cache",
                  metadata: {
                    filename: "test.stl"
                  }
                }],
                owner: User.last,
                creator_id: creator.id.to_s,
                collection_id: collection.id.to_s,
                license: "MIT",
                sensitive: true,
                permission_preset: "public",
                tag_list: ["tag1", "tag2"],
                name: "Only used for single model upload").once
          end

          it "redirect back to index after upload" do
            post_models
            expect(response).to redirect_to("/models")
          end

          it "clears returnable session param" do
            post_models
            expect(session[:return_after_new]).to be_nil
          end
        end

        context "with multiple compressed files", :as_contributor do
          let(:files) {
            {
              "0" => {
                id: "upload_1",
                name: "test.zip"
              },
              "1" => {
                id: "upload_2",
                name: "example.zip"
              }
            }
          }

          it "enqueues separate archive processing jobs" do # rubocop:disable RSpec/ExampleLength
            post_models
            expect(ProcessUploadedFileJob).to have_been_enqueued
              .with(Library.first.id, hash_including({metadata: {filename: "test.zip"}}), hash_including({})).once
              .and have_been_enqueued
              .with(Library.first.id, hash_including({metadata: {filename: "example.zip"}}), hash_including({})).once
          end

          it "does not provide model name field" do # rubocop:disable RSpec/ExampleLength
            post_models
            expect(ProcessUploadedFileJob).to have_been_enqueued
              .with(Library.first.id, hash_including({}), hash_not_including({name: "Only for single model upload"})).twice
          end
        end

        context "with multiple uncompressed files", :as_contributor do
          let(:files) {
            {
              "0" => {
                id: "upload_1",
                name: "test.stl"
              },
              "1" => {
                id: "upload_2",
                name: "readme.txt"
              }
            }
          }

          it "enqueues a single processing job for all files combined" do # rubocop:disable RSpec/ExampleLength
            post_models
            expect(ProcessUploadedFileJob).to have_been_enqueued
              .with(Library.first.id,
                array_including(
                  hash_including({metadata: {filename: "test.stl"}}),
                  hash_including({metadata: {filename: "readme.txt"}})
                ),
                hash_including({})).once
          end

          it "provides model name field" do # rubocop:disable RSpec/ExampleLength
            post_models
            expect(ProcessUploadedFileJob).to have_been_enqueued
              .with(Library.first.id, array_including, hash_including({name: "Only used for single model upload"}))
          end
        end

        context "with an uncompressed file and a compressed one", :as_contributor do
          let(:files) {
            {
              "0" => {
                id: "upload_1",
                name: "test.zip"
              },
              "1" => {
                id: "upload_2",
                name: "model.stl"
              }
            }
          }

          it "enqueues one processing job for all files combined" do # rubocop:disable RSpec/ExampleLength
            post_models
            expect(ProcessUploadedFileJob).to have_been_enqueued
              .with(Library.first.id,
                array_including(
                  hash_including({metadata: {filename: "test.zip"}}),
                  hash_including({metadata: {filename: "model.stl"}})
                ),
                hash_including({})).once
          end
        end

        context "without upload permission", :as_member do
          let(:files) { {} }

          it "denies members" do
            post_models
            expect(response).to have_http_status(:forbidden)
          end
        end
      end
    end
  end
end
