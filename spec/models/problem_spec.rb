require "rails_helper"

RSpec.describe Problem do
  include Rails.application.routes.url_helpers

  describe "querying visible scope" do
    let(:settings) do
      {
        missing: :silent,
        empty: :info,
        nesting: :warning,
        inefficient: :info,
        duplicate: :warning
      }
    end

    before do
      create_list(:problem, 3, :missing)
      create_list(:problem, 3, :inefficient)
    end

    it "lists visible problems" do # rubocop:todo RSpec/MultipleExpectations
      expect(described_class.visible(settings).length).to eq 3
      expect(described_class.visible(settings).map { |it| it.category.to_sym }).to include :inefficient
    end

    it "does not include silenced problems" do
      expect(described_class.visible(settings).map { |it| it.category.to_sym }).not_to include :missing
    end

    it "falls back to default visibility settings" do # rubocop:todo RSpec/MultipleExpectations
      expect(described_class.visible({missing: :silent}).length).to eq 3
      expect(described_class.visible({missing: :silent}).map { |it| it.category.to_sym }).to include :inefficient
    end
  end

  context "when being ignored" do
    it "have an ignored flag" do
      p = build(:problem)
      expect(p).to respond_to(:ignored)
    end

    it "leaves out ignored problems by default" do
      create(:problem)
      create(:problem, ignored: true)
      expect(described_class.count).to eq(1)
    end

    it "includes ignored problems when specified" do
      create(:problem)
      create(:problem, ignored: true)
      expect(described_class.unscoped.count).to eq(2)
    end

    it "can ignore an existing problem" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      p = create(:problem)
      expect(p.ignored).to be(false)
      expect(described_class.count).to eq(1)
      p.update!(ignored: true)
      expect(p.ignored).to be(true)
      expect(described_class.count).to eq(0)
    end

    it "can unignore an existing problem" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      p = create(:problem, ignored: true)
      expect(p.ignored).to be(true)
      expect(described_class.count).to eq(0)
      p.update!(ignored: false)
      expect(p.ignored).to be(false)
      expect(described_class.count).to eq(1)
    end
  end

  context "when updating problem state" do
    let(:model) { create(:model, license: nil) }

    it "creates a problem that should exist but doesn't" do
      expect {
        described_class.create_or_clear model, :no_license, model.license.blank?
      }.to change(described_class, :count).from(0).to(1)
    end

    it "removes a problem that shouldn't exist but does" do
      described_class.create_or_clear model, :no_license, model.license.blank?
      model.update!(license: "CC-BY-4.0")
      expect {
        described_class.create_or_clear model, :no_license, model.license.blank?
      }.to change(described_class, :count).from(1).to(0)
    end

    it "does nothing with a problem that shouldn't exist and doesn't" do
      model.update!(license: "CC-BY-4.0")
      expect {
        described_class.create_or_clear model, :no_license, model.license.blank?
      }.not_to change(described_class, :count)
    end

    it "does nothing with a problem that should exist and does" do
      described_class.create_or_clear model, :no_license, model.license.blank?
      expect {
        described_class.create_or_clear model, :no_license, model.license.blank?
      }.not_to change(described_class, :count)
    end
  end

  describe ".resolve_batch" do
    it "resolves multiple problems and returns removed_ids" do
      m1 = create(:model)
      m2 = create(:model)
      p1 = create(:problem_on_model, category: :empty, problematic: m1)
      p2 = create(:problem_on_model, category: :empty, problematic: m2)
      ids = [p1.id, p2.id]

      result = described_class.resolve_batch([p1, p2])

      expect(result[:removed_ids]).to match_array(ids)
      expect(result[:redirect]).to be_nil
      expect(described_class.unscoped.where(id: ids)).not_to exist
      expect(Model.where(id: [m1.id, m2.id])).not_to exist
    end

    it "returns redirect for single problem when resolution redirects" do
      model = create(:model, license: nil)
      problem = create(:problem_on_model, category: :no_license, problematic: model)

      result = described_class.resolve_batch([problem])

      expect(result[:redirect]).to eq(edit_model_path(model))
      expect(result[:removed_ids]).to be_empty
    end

    it "ignores problems when override_action: :ignore" do
      model = create(:model)
      problem = create(:problem_on_model, category: :empty, problematic: model)

      result = described_class.resolve_batch([problem], override_action: :ignore)

      expect(result[:ignored_ids]).to eq([problem.id])
      expect(result[:removed_ids]).to be_empty
      expect(problem.reload.ignored).to be true
    end

    it "does not unique-enqueue FileConversionJob while the batch transaction is open" do
      file = create(:model_file)
      problem = create(:problem, category: :inefficient, problematic: file)
      enqueued_in_open_txn = nil
      allow_any_instance_of(ModelFile).to receive(:convert_later) do
        enqueued_in_open_txn = ActiveRecord::Base.connection.transaction_open?
      end

      described_class.resolve_batch([problem])

      expect(enqueued_in_open_txn).to be(false)
    end
  end
end
