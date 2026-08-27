# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Problems category classes" do
  include Rails.application.routes.url_helpers

  def create_problem(category:, problematic:)
    create(:problem, category: category, problematic: problematic)
  end

  shared_examples "ignorable" do |klass:, problem_factory:|
    it "marks the problem ignored and returns { ignored: true }" do
      problem = instance_exec(&problem_factory)

      result = klass.new.resolve!(problem, action: :ignore)

      expect(result).to eq(ignored: true)
      expect(problem.reload.ignored).to be(true)
    end
  end

  shared_examples "destructive_resolution" do |klass:, problem_factory:, destructive_method: :delete_from_disk_and_destroy|
    it "destroys the problem record before running the destructive side effect" do
      problem = instance_exec(&problem_factory)
      problematic = problem.problematic
      problem_id = problem.id

      allow(problematic).to receive(destructive_method) do
        expect(Problem.unscoped.where(id: problem_id)).not_to exist
      end

      result = klass.new.resolve!(problem, action: :destroy)

      expect(result).to eq(removed: true)
      expect(Problem.unscoped.where(id: problem_id)).not_to exist
      expect(problematic).to have_received(destructive_method)
    end
  end

  shared_examples "redirecting_resolution" do |klass:, problem_factory:, action:, expected_redirect:|
    it "returns a redirect result" do
      problem = instance_exec(&problem_factory)

      result = klass.new.resolve!(problem, action: action)

      expect(result).to eq(redirect: instance_exec(problem, &expected_redirect))
    end
  end

  describe Problems::Duplicate do
    it_behaves_like "ignorable",
      klass: described_class,
      problem_factory: -> { create_problem(category: :duplicate, problematic: create(:model_file)) }

    it_behaves_like "destructive_resolution",
      klass: described_class,
      problem_factory: -> { create_problem(category: :duplicate, problematic: create(:model_file)) }
  end

  describe Problems::EmptyFile do
    it_behaves_like "ignorable",
      klass: described_class,
      problem_factory: -> { create_problem(category: :empty, problematic: create(:model_file)) }

    it_behaves_like "destructive_resolution",
      klass: described_class,
      problem_factory: -> { create_problem(category: :empty, problematic: create(:model_file)) }
  end

  describe Problems::MissingFile do
    it_behaves_like "ignorable",
      klass: described_class,
      problem_factory: -> { create_problem(category: :missing, problematic: create(:model_file)) }

    it_behaves_like "destructive_resolution",
      klass: described_class,
      problem_factory: -> { create_problem(category: :missing, problematic: create(:model_file)) }
  end

  describe Problems::MissingModel do
    it_behaves_like "ignorable",
      klass: described_class,
      problem_factory: -> { create_problem(category: :missing, problematic: create(:model)) }

    it_behaves_like "destructive_resolution",
      klass: described_class,
      problem_factory: -> { create_problem(category: :missing, problematic: create(:model)) }
  end

  describe Problems::MissingLibrary do
    it_behaves_like "ignorable",
      klass: described_class,
      problem_factory: -> { create_problem(category: :missing, problematic: create(:library)) }

    it_behaves_like "destructive_resolution",
      klass: described_class,
      problem_factory: -> { create_problem(category: :missing, problematic: create(:library)) },
      destructive_method: :destroy!
  end

  describe Problems::NonManifold do
    it_behaves_like "ignorable",
      klass: described_class,
      problem_factory: -> { create_problem(category: :non_manifold, problematic: create(:model_file)) }

    it_behaves_like "redirecting_resolution",
      klass: described_class,
      problem_factory: -> { create_problem(category: :non_manifold, problematic: create(:model_file)) },
      action: :show,
      expected_redirect: ->(problem) { model_model_file_path(problem.problematic.model, problem.problematic) }
  end

  describe Problems::HttpError do
    it_behaves_like "ignorable",
      klass: described_class,
      problem_factory: -> {
        model = create(:model, links_attributes: [{url: "http://example.com"}])
        create_problem(category: :http_error, problematic: model.links.first)
      }

    it_behaves_like "redirecting_resolution",
      klass: described_class,
      problem_factory: -> {
        model = create(:model, links_attributes: [{url: "http://example.com"}])
        create_problem(category: :http_error, problematic: model.links.first)
      },
      action: :edit,
      expected_redirect: ->(problem) { edit_model_path(problem.problematic.linkable) }
  end

  describe Problems::NoLicense do
    it_behaves_like "ignorable",
      klass: described_class,
      problem_factory: -> { create_problem(category: :no_license, problematic: create(:model, license: nil)) }

    it_behaves_like "redirecting_resolution",
      klass: described_class,
      problem_factory: -> { create_problem(category: :no_license, problematic: create(:model, license: nil)) },
      action: :edit,
      expected_redirect: ->(problem) { edit_model_path(problem.problematic) }
  end

  describe Problems::NoLinks do
    it_behaves_like "ignorable",
      klass: described_class,
      problem_factory: -> { create_problem(category: :no_links, problematic: create(:model, links_attributes: [])) }

    it_behaves_like "redirecting_resolution",
      klass: described_class,
      problem_factory: -> { create_problem(category: :no_links, problematic: create(:model, links_attributes: [])) },
      action: :edit,
      expected_redirect: ->(problem) { edit_model_path(problem.problematic) }
  end

  describe Problems::NoCreator do
    it_behaves_like "ignorable",
      klass: described_class,
      problem_factory: -> { create_problem(category: :no_creator, problematic: create(:model, creator: nil)) }

    it_behaves_like "redirecting_resolution",
      klass: described_class,
      problem_factory: -> { create_problem(category: :no_creator, problematic: create(:model, creator: nil)) },
      action: :edit,
      expected_redirect: ->(problem) { edit_model_path(problem.problematic) }
  end

  describe Problems::NoTags do
    it_behaves_like "ignorable",
      klass: described_class,
      problem_factory: -> { create_problem(category: :no_tags, problematic: create(:model, tag_list: [])) }

    it_behaves_like "redirecting_resolution",
      klass: described_class,
      problem_factory: -> { create_problem(category: :no_tags, problematic: create(:model, tag_list: [])) },
      action: :edit,
      expected_redirect: ->(problem) { edit_model_path(problem.problematic) }
  end

  describe Problems::NoImage do
    it_behaves_like "ignorable",
      klass: described_class,
      problem_factory: -> { create_problem(category: :no_image, problematic: create(:model)) }

    it_behaves_like "redirecting_resolution",
      klass: described_class,
      problem_factory: -> { create_problem(category: :no_image, problematic: create(:model)) },
      action: :upload,
      expected_redirect: ->(problem) { model_path(problem.problematic, anchor: "upload-form") }
  end

  describe Problems::No3dModel do
    it_behaves_like "ignorable",
      klass: described_class,
      problem_factory: -> { create_problem(category: :no_3d_model, problematic: create(:model)) }

    it_behaves_like "redirecting_resolution",
      klass: described_class,
      problem_factory: -> { create_problem(category: :no_3d_model, problematic: create(:model)) },
      action: :upload,
      expected_redirect: ->(problem) { model_path(problem.problematic, anchor: "upload-form") }
  end

  describe Problems::Inefficient do
    it_behaves_like "ignorable",
      klass: described_class,
      problem_factory: -> { create_problem(category: :inefficient, problematic: create(:model_file)) }

    it "marks resolving/in_progress, triggers conversion, and returns { in_progress: true }" do
      file = create(:model_file)
      problem = create_problem(category: :inefficient, problematic: file)

      allow(file).to receive(:convert_later)

      result = described_class.new.resolve!(problem, action: :convert)

      expect(result).to eq(in_progress: true)
      expect(problem.reload).to be_resolving
      expect(problem.in_progress).to be(true)
      expect(file).to have_received(:convert_later).with(:threemf)
    end
  end

  describe Problems::FileNaming do
    it_behaves_like "ignorable",
      klass: described_class,
      problem_factory: -> { create_problem(category: :file_naming, problematic: create(:model)) }

    it "marks resolving/in_progress, triggers organize, and returns { in_progress: true }" do
      model = create(:model)
      problem = create_problem(category: :file_naming, problematic: model)

      allow(model).to receive(:organize_later)

      result = described_class.new.resolve!(problem, action: :organize)

      expect(result).to eq(in_progress: true)
      expect(problem.reload).to be_resolving
      expect(problem.in_progress).to be(true)
      expect(model).to have_received(:organize_later).with(delay: 0)
    end
  end

  describe Problems::Nesting do
    it_behaves_like "ignorable",
      klass: described_class,
      problem_factory: -> { create_problem(category: :nesting, problematic: create(:model)) }

    it "triggers merge, destroys the problem, and returns { removed: true }" do
      model = create(:model)
      allow(model).to receive(:contained_models).and_return([])
      allow(model).to receive(:merge!)

      problem = create_problem(category: :nesting, problematic: model)
      problem_id = problem.id

      result = described_class.new.resolve!(problem, action: :merge)

      expect(result).to eq(removed: true)
      expect(Problem.unscoped.where(id: problem_id)).not_to exist
      expect(model).to have_received(:merge!).with([])
    end
  end
end
