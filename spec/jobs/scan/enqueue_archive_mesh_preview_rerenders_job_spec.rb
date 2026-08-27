# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scan::EnqueueArchiveMeshPreviewRerendersJob do
  include ActiveJob::TestHelper

  around do |ex|
    Dir.mktmpdir("mesh_rerender_spec") do |tmpdir|
      Library.destroy_all
      @library = create(:library, path: tmpdir)
      @model = create(:model, library: @library, path: "m")
      FileUtils.mkdir_p(File.join(tmpdir, "m"))
      @file = create(:model_file, model: @model, filename: "pack.zip")
      ex.run
    end
  end

  def create_mesh!(pathname:, status:)
    ArchiveEntry.create!(
      model_file: @file,
      pathname: pathname,
      kind: "mesh",
      status: status,
      size: 100
    )
  end

  it "enqueues listed and preview_failed meshes by default" do
    listed = create_mesh!(pathname: "b.stl", status: "listed")
    failed = create_mesh!(pathname: "c.stl", status: "preview_failed")
    ArchiveEntry.create!(
      model_file: @file,
      pathname: "img.png",
      kind: "image",
      status: "listed",
      size: 50
    )

    expect {
      described_class.perform_now(limit: 10, batch_size: 10, stagger: 0)
    }.to have_enqueued_job(Scan::ModelFile::PreviewArchiveEntryJob).exactly(2).times

    expect(listed.reload.status).to eq("preview_pending")
    expect(failed.reload.status).to eq("preview_pending")
  end

  it "does not enqueue preview_ready rows by default" do
    ready = create_mesh!(pathname: "a.stl", status: "preview_ready")
    listed = create_mesh!(pathname: "b.stl", status: "listed")

    expect {
      described_class.perform_now(limit: 10, batch_size: 10, stagger: 0)
    }.to have_enqueued_job(Scan::ModelFile::PreviewArchiveEntryJob).once

    expect(ready.reload.status).to eq("preview_ready")
    expect(listed.reload.status).to eq("preview_pending")
  end

  it "enqueues preview_ready when include_ready is true" do
    ready = create_mesh!(pathname: "a.stl", status: "preview_ready")
    listed = create_mesh!(pathname: "b.stl", status: "listed")

    expect {
      described_class.perform_now(limit: 10, batch_size: 10, stagger: 0, include_ready: true)
    }.to have_enqueued_job(Scan::ModelFile::PreviewArchiveEntryJob).exactly(2).times

    expect(ready.reload.status).to eq("preview_pending")
    expect(listed.reload.status).to eq("preview_pending")
  end

  it "enqueues preview_ready when INCLUDE_READY=1" do
    ready = create_mesh!(pathname: "a.stl", status: "preview_ready")

    ClimateControl.modify(INCLUDE_READY: "1") do
      expect {
        described_class.perform_now(limit: 10, batch_size: 10, stagger: 0)
      }.to have_enqueued_job(Scan::ModelFile::PreviewArchiveEntryJob).once
    end

    expect(ready.reload.status).to eq("preview_pending")
  end
end
