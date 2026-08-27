# frozen_string_literal: true

require "rails_helper"
require "support/mock_directory"

RSpec.describe Model::Merge do
  around do |ex|
    MockDirectory.create([
      "parent/parent_part.stl",
      "parent/child/child_part.stl"
    ]) do |path|
      @library_path = path
      ex.run
    end
  end

  let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable
  let!(:parent) { create(:model, library: library, path: "parent") }
  let!(:child) { create(:model, library: library, path: "parent/child") }
  let!(:parent_file) { create(:model_file, model: parent, filename: "parent_part.stl") }
  let!(:child_file) { create(:model_file, model: child, filename: "child_part.stl") }

  it "stamps ScanContext on target, sources, and model_files before writes" do
    seen = nil
    allow(ScanContext).to receive(:apply!).and_wrap_original do |method, *records|
      seen ||= records.flatten
      method.call(*records)
    end

    described_class.call(parent, child)

    expect(seen).to include(parent, child, parent_file, child_file)
  end

  it "does not enqueue CheckForProblemsJob" do
    expect { described_class.call(parent, child) }
      .not_to have_enqueued_job(Scan::Model::CheckForProblemsJob)
  end

  it "persists MergeHistory and removes the source when uniqueness Redlock would raise" do
    stub_unique_enqueue_redlock_error

    expect { parent.merge!(child) }.not_to raise_error

    expect(MergeHistory.where(target_model: parent).count).to eq 1
    expect(Model.where(id: child.id)).not_to exist
  end

  it "leaves global uniqueness on_redis_connection_error unset" do
    initializer = File.read(Rails.root.join("config/initializers/active_job_uniqueness.rb"))
    expect(initializer).not_to match(/^\s*config\.on_redis_connection_error\s*=/)
  end

  it "reattaches adopted files after commit so storage matches path_within_library" do # rubocop:todo RSpec/MultipleExpectations
    described_class.call(parent, child)
    parent.model_files.reload.each do |file|
      expect(file.attachment.id).to eq file.path_within_library
      expect(file.exists_on_storage?).to be true
    end
  end
end

RSpec.describe Model::Merge, "rollback after adopt" do
  around do |ex|
    MockDirectory.create([
      "root/target/keep.stl",
      "root/source/part.stl"
    ]) do |path|
      @library_path = path
      ex.run
    end
  end

  let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable
  let!(:target) { create(:model, library: library, path: "root/target") }
  let!(:source) { create(:model, library: library, path: "root/source") }
  let!(:source_file) { create(:model_file, model: source, filename: "part.stl") }

  it "rolls back source file rows and leaves source storage at the old path" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
    old_path = source_file.path_within_library
    old_attachment_id = source_file.attachment.id
    expect(library.has_file?(old_path)).to be true
    allow(MergeHistory).to receive(:create!).and_raise("forced rollback")

    expect { described_class.call(target, source) }.to raise_error("forced rollback")

    expect(source.reload.model_files.count).to eq 1
    expect(MergeHistory.where(target_model: target).count).to eq 0
    source_file.reload
    expect(source_file.attachment.id).to eq old_attachment_id
    expect(library.has_file?(old_path)).to be true
    expect(source_file.exists_on_storage?).to be true
  end
end
