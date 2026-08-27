require "rails_helper"
require "support/mock_directory"

# problems GET    /problems(.:format)                                                     problems#index
#  problem PATCH  /problems/:id(.:format)                                                 problems#update

RSpec.describe "Problems" do
  context "when signed out" do
    it "needs testing when multiuser is enabled"
  end

  context "when signed in" do
    describe "GET /problems", :as_contributor do
      it "is denied to contributors" do
        get "/problems/index"
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "GET /problems", :as_moderator do
      before do
        create_list(:problem, 2, category: :inefficient)
        create_list(:problem_on_model, 3, category: :missing)
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

      context "when filtering by category" do
        it "only shows selected categories" do
          get "/problems/index", params: {"category[]": "missing"}
          expect(assigns(:problems).length).to eq 3
        end

        it "can show more than one category" do
          get "/problems/index", params: {"category[]": ["missing", "inefficient"]}
          expect(assigns(:problems).length).to eq 5
        end
      end

      context "when filtering by object type" do
        it "only shows selected types" do
          get "/problems/index", params: {"type[]": "model"}
          expect(assigns(:problems).length).to eq 3
        end

        it "can show more than one type" do
          get "/problems/index", params: {"type[]": ["model", "model_file"]}
          expect(assigns(:problems).length).to eq 5
        end
      end

      context "when filtering by severity" do
        it "only shows selected severities" do
          get "/problems/index", params: {"severity[]": "info"}
          expect(assigns(:problems).length).to eq 2
        end

        it "can show more than one severity" do
          get "/problems/index", params: {"severity[]": ["danger", "info"]}
          expect(assigns(:problems).length).to eq 5
        end
      end

      context "when filtering by severity AND category" do
        it "only shows the intersection of both" do
          get "/problems/index", params: {"category[]": ["missing"], "severity[]": ["danger", "info"]}
          expect(assigns(:problems).length).to eq 3
        end
      end
    end

    describe "PATCH /problems/:id" do
      let(:problem) { create(:problem) }

      before { patch "/problems/#{problem.to_param}", params: {problem: {ignored: true}} }

      it "updates the problem and returns to list", :as_moderator do
        expect(response).to redirect_to("/problems")
      end

      it "is denied to non-moderators", :as_contributor do
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST /problems/:id/resolve with destroy resolution", :as_moderator do
      it "destroys the problem record before running the destructive side effect" do
        problem = create(:problem_on_model, category: :empty)
        problem_id = problem.id
        allow_any_instance_of(Model).to receive(:delete_from_disk_and_destroy) do
          expect(Problem.exists?(problem_id)).to be false
        end
        post resolve_problem_path(problem), params: {resolve: "1"}
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "POST /problems/:id/resolve nesting merge", :as_moderator do
      around do |ex|
        MockDirectory.create([
          "parent/parent_part.stl",
          "parent/child/child_part.stl"
        ]) do |path|
          @library_path = path
          ex.run
        end
      end

      it "persists merge and destroys the problem when uniqueness Redlock would raise" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
        library = create(:library, path: @library_path) # rubocop:todo RSpec/InstanceVariable
        parent = create(:model, library: library, path: "parent")
        child = create(:model, library: library, path: "parent/child")
        create(:model_file, model: parent, filename: "parent_part.stl")
        create(:model_file, model: child, filename: "child_part.stl")
        problem = create(:problem_on_model, category: :nesting, problematic: parent)
        problem_id = problem.id
        stub_unique_enqueue_redlock_error

        post resolve_problem_path(problem), params: {resolve: "1"}

        expect(response).to have_http_status(:redirect)
        expect(response).not_to have_http_status(:internal_server_error)
        expect(Problem.unscoped.where(id: problem_id)).not_to exist
        expect(MergeHistory.where(target_model: parent).count).to eq 1
        expect(Model.where(id: child.id)).not_to exist
      end
    end
  end
end
