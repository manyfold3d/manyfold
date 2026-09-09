# frozen_string_literal: true

require "rails_helper"
require "support/mock_directory"

RSpec.describe Scan::DedupLibraryJob do
  let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

  around do |ex|
    MockDirectory.create([
      "DC/Batman Pack/model.stl",
      "DC/Batman Pack (2)/model.stl",
      "DC/Other Batman/model.stl"
    ]) do |path|
      @library_path = path
      Library.destroy_all
      ex.run
    end
  end

  def add_meshes(model, pathnames)
    file = create(:model_file, model: model, filename: "pack.zip", attachment: nil)
    pathnames.each do |pathname|
      ArchiveEntry.create!(
        model_file: file,
        pathname: pathname,
        kind: "mesh",
        status: "listed",
        size: 100
      )
    end
  end

  def jsonl_records
    dir = File.join(library.path, ".spark-curate")
    files = Dir.glob(File.join(dir, "merges-dedup-*.jsonl"))
    return [] if files.empty?

    File.readlines(files.max, encoding: "UTF-8").filter_map do |line|
      JSON.parse(line) if line.strip.present?
    end
  end

  it "does not call Model#merge! or Model::Merge" do
    create(:model, library: library, path: "DC/Batman Pack", name: "Batman Pack")

    allow(Model::Merge).to receive(:call)
    described_class.perform_now(library_id: library.id)
    expect(Model::Merge).not_to have_received(:call)
  end

  it "has no merge apply calls in the job or planner source" do
    job_src = Rails.root.join("app/jobs/scan/dedup_library_job.rb").read
    planner_src = Rails.root.join("app/services/scan/dedup_library.rb").read
    expect(job_src).not_to match(/\.merge!|Model::Merge\.call/)
    expect(planner_src).not_to match(/\.merge!|Model::Merge\.call/)
  end

  it "succeeds with an empty candidate set and writes a reviewable JSONL" do
    create(:model, library: library, path: "DC/Other Batman", name: "Other Batman")

    expect {
      described_class.perform_now(library_id: library.id)
    }.not_to change(Model, :count)

    files = Dir.glob(File.join(library.path, ".spark-curate", "merges-dedup-*.jsonl"))
    expect(files).not_to be_empty
    expect(jsonl_records).to eq([])
  end

  it "plans same_pack listing STRONG without merging" do # rubocop:todo RSpec/ExampleLength
    target = create(:model, library: library, path: "DC/Batman Pack", name: "Batman Pack")
    source = create(:model, library: library, path: "DC/Batman Pack (2)", name: "Batman Pack (2)")
    add_meshes(target, %w[a.stl b.stl c.stl])
    add_meshes(source, %w[a.stl b.stl c.stl])

    expect {
      described_class.perform_now(library_id: library.id)
    }.not_to change(Model, :count)

    expect(Model.exists?(source.id)).to be true
    planned = jsonl_records.select { |r| r["decision"] == "merge" }
    expect(planned.size).to eq(1)
    expect(planned.first["composition"]).to eq("same_pack")
    expect(planned.first["merge_hitl"]).to eq("hitl_all")
  end

  it "refuses commons and does not plan a merge" do
    left = create(:model, library: library, path: "DC/Batman Pack", name: "Batman Pack")
    right = create(:model, library: library, path: "DC/Other Batman", name: "Other Batman")
    add_meshes(left, %w[shared.stl a1.stl a2.stl a3.stl])
    add_meshes(right, %w[shared.stl b1.stl b2.stl b3.stl])

    described_class.perform_now(library_id: library.id)

    records = jsonl_records
    expect(records).not_to be_empty
    expect(records).to all(include("decision" => "keep_separate", "composition" => "commons"))
    expect(records.none? { |r| r["decision"] == "merge" }).to be true
  end

  it "invokes SPARK_CURATE_CMD as argv without user interpolation" do
    create(:model, library: library, path: "DC/Other Batman", name: "Other Batman")
    status = instance_double(Process::Status, success?: true, exitstatus: 0)
    allow(Open3).to receive(:capture3).with("/bin/true").and_return(["", "", status])

    ClimateControl.modify(SPARK_CURATE_CMD: "/bin/true") do
      described_class.perform_now(library_id: library.id)
    end
    expect(Open3).to have_received(:capture3).with("/bin/true")
  end

  it "fails loud when SPARK_CURATE_CMD exits non-zero" do
    ClimateControl.modify(SPARK_CURATE_CMD: "/bin/false") do
      expect {
        described_class.perform_now(library_id: library.id)
      }.to raise_error(Scan::DedupLibrary::CommandFailed)
    end
  end
end
