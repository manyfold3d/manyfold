require "rails_helper"
require "zip"
require "base64"
require "open3"

RSpec.describe ArchiveEntryService do
  include ActiveJob::TestHelper

  around do |ex|
    Dir.mktmpdir("archive_entry_spec") do |tmpdir|
      @library_path = tmpdir
      model_dir = File.join(tmpdir, "model_a")
      FileUtils.mkdir_p(model_dir)
      @zip_path = File.join(model_dir, "pack.zip")
      Zip::File.open(@zip_path, create: true) do |zip|
        zip.get_output_stream("readme.txt") { |f| f.write("hello") }
        zip.get_output_stream("parts/widget.stl") { |f| f.write("solid empty\nendsolid empty\n") }
        zip.get_output_stream("pics/shot.png") do |f|
          # minimal 1x1 PNG
          f.write(Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="))
        end
        zip.get_output_stream("__MACOSX/._junk") { |f| f.write("x") }
      end
      Library.destroy_all
      @library = create(:library, path: tmpdir)
      @model = create(:model, library: @library, path: "model_a")
      @file = create(:model_file, model: @model, filename: "pack.zip", attachment: nil)
      @file.attach_existing_file!(refresh: false)
      ex.run
    end
  end

  describe "#list!" do
    it "lists files inside the archive and skips ignored paths" do
      entries = described_class.new(@file).list!
      paths = entries.map(&:pathname)
      expect(paths).to include("readme.txt", "parts/widget.stl", "pics/shot.png")
      expect(paths).not_to include("__MACOSX/._junk")
      expect(@file.reload.archive_entries_listed_count).to eq(3)
    end

    it "classifies mesh and image kinds" do
      described_class.new(@file).list!
      expect(@file.archive_entries.find_by(pathname: "parts/widget.stl").kind).to eq("mesh")
      expect(@file.archive_entries.find_by(pathname: "pics/shot.png").kind).to eq("image")
      expect(@file.archive_entries.find_by(pathname: "readme.txt").kind).to eq("other")
    end
  end

  describe "#enqueue_previews!" do
    it "enqueues preview jobs for mesh and image entries" do
      service = described_class.new(@file)
      service.list!
      expect {
        service.enqueue_previews!
      }.to have_enqueued_job(Scan::ModelFile::PreviewArchiveEntryJob).at_least(:twice)
    end

    it "staggers preview jobs instead of flooding the queue" do
      service = described_class.new(@file)
      service.list!
      expect {
        service.enqueue_previews!(stagger: 1.0, batch_size: 10)
      }.to have_enqueued_job(Scan::ModelFile::PreviewArchiveEntryJob).at_least(:twice)
      jobs = enqueued_jobs.select { |j| j[:job] == Scan::ModelFile::PreviewArchiveEntryJob }
      waits = jobs.filter_map { |j| j[:at] }
      expect(waits.size).to be >= 1
    end

    it "skips mesh previews when images_only" do
      service = described_class.new(@file)
      service.list!
      expect {
        service.enqueue_previews!(images_only: true)
      }.to have_enqueued_job(Scan::ModelFile::PreviewArchiveEntryJob).once
      expect(@file.archive_entries.find_by(pathname: "pics/shot.png").status).to eq("preview_pending")
      expect(@file.archive_entries.find_by(pathname: "parts/widget.stl").status).to eq("listed")
    end
  end

  describe "#extract_to_cache!" do
    it "extracts a single mesh into .manyfold archive_cache" do
      service = described_class.new(@file)
      service.list!
      entry = @file.archive_entries.find_by!(pathname: "parts/widget.stl")
      rel = service.extract_to_cache!(entry)
      expect(rel).to include(".manyfold/archive_cache/")
      expect(File.file?(File.join(@library_path, rel))).to be true
      expect(entry.reload.extracted_path).to eq(rel)
    end
  end

  describe "#extract_mesh_and_preview!" do
    def png_1x1
      Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==")
    end

    def stub_node_thumbnail_on(service, success: true, stderr: "render failed")
      status = instance_double(Process::Status, success?: success, exitstatus: success ? 0 : 1)
      allow(service).to receive(:system)
        .with("command", "-v", "node", out: File::NULL, err: File::NULL)
        .and_return(true)
      allow(Open3).to receive(:capture3) do |_bin, _script, mesh_path, preview_path|
        expect(File.extname(mesh_path).downcase).to eq(".stl")
        if success
          FileUtils.mkdir_p(File.dirname(preview_path))
          File.binwrite(preview_path, png_1x1)
        end
        ["", success ? "" : stderr, status]
      end
    end

    def assimp_triangle_scene
      vert = Struct.new(:x, :y, :z)
      face = Struct.new(:indices)
      mesh = Struct.new(:vertices, :faces)
      scene = instance_double("AssimpScene")
      allow(scene).to receive(:apply_post_processing).and_return(scene)
      allow(scene).to receive(:meshes).and_return([
        mesh.new(
          [vert.new(0.0, 0.0, 0.0), vert.new(1.0, 0.0, 0.0), vert.new(0.0, 1.0, 0.0)],
          [face.new([0, 1, 2])]
        )
      ])
      scene
    end

    def ensure_assimp_constant!
      return if defined?(Assimp)

      stub_const("Assimp", Module.new)
      stub_const("Assimp::PostProcessSteps", Class.new)
      allow(Assimp::PostProcessSteps).to receive(:[]).and_return(0)
    end

    def add_obj_member!
      Zip::File.open(@zip_path) do |zip|
        zip.get_output_stream("parts/widget.obj") { |f| f.write("v 0 0 0\nv 1 0 0\nv 0 1 0\nf 1 2 3\n") }
      end
      @file.attach_existing_file!(refresh: true)
    end

    it "writes a real PNG thumbnail for an STL when node is available" do
      skip "node not on PATH" unless system("command", "-v", "node", out: File::NULL, err: File::NULL)

      # Replace empty STL with a small cube so the rasterizer has triangles
      Zip::File.open(@zip_path) do |zip|
        zip.remove("parts/widget.stl")
        zip.get_output_stream("parts/widget.stl") do |f|
          f.write(<<~STL)
            solid cube
              facet normal 0 0 1
                outer loop
                  vertex 0 0 0
                  vertex 1 0 0
                  vertex 0 1 0
                endloop
              endfacet
            endsolid cube
          STL
        end
      end
      @file.attach_existing_file!(refresh: true)

      service = described_class.new(@file)
      service.list!
      entry = @file.archive_entries.find_by!(pathname: "parts/widget.stl")
      service.extract_mesh_and_preview!(entry)
      expect(entry.reload.status).to eq("preview_ready")
      abs = entry.absolute_preview_path
      expect(File.file?(abs)).to be true
      expect(File.binread(abs, 8)).to eq("\x89PNG\r\n\x1a\n".b)
      # Real raster is larger than the 1x1 / minimal stub paths
      expect(File.size(abs)).to be > 200
    end

    it "marks preview_ready when node writes a non-empty PNG for an STL" do
      service = described_class.new(@file)
      stub_node_thumbnail_on(service, success: true)
      service.list!
      entry = @file.archive_entries.find_by!(pathname: "parts/widget.stl")
      service.extract_mesh_and_preview!(entry)
      expect(entry.reload.status).to eq("preview_ready")
      expect(entry.preview_path).to include(".manyfold/derivatives/archives/")
      expect(entry.preview_path).to include("preview.png")
      expect(File.file?(entry.absolute_preview_path)).to be true
      expect(File.size(entry.absolute_preview_path)).to be > 0
    end

    it "loads Assimp, converts non-STL to STL, then invokes mesh_thumbnail only on the STL" do
      add_obj_member!
      ensure_assimp_constant!
      scene = assimp_triangle_scene
      allow(Assimp).to receive(:import_file).and_return(scene)

      service = described_class.new(@file)
      stub_node_thumbnail_on(service, success: true)
      expect(service).to receive(:load_assimp!).and_wrap_original do |orig|
        result = orig.call
        expect(defined?(Assimp)).to be_truthy
        result
      end

      service.list!
      entry = @file.archive_entries.find_by!(pathname: "parts/widget.obj")
      service.extract_mesh_and_preview!(entry)
      expect(Assimp).to have_received(:import_file)
      expect(entry.reload.status).to eq("preview_ready")
      expect(entry.preview_path).to include(".manyfold/")
      expect(File.size(entry.absolute_preview_path)).to be > 0
    end

    it "does not invoke mesh_thumbnail on a non-STL when Assimp conversion fails" do
      add_obj_member!
      service = described_class.new(@file)
      allow(service).to receive(:load_assimp!).and_return(true)
      allow(service).to receive(:convert_mesh_to_stl_tempfile!).and_return(nil)
      expect(Open3).not_to receive(:capture3)

      service.list!
      entry = @file.archive_entries.find_by!(pathname: "parts/widget.obj")
      service.extract_mesh_and_preview!(entry)
      expect(entry.reload.status).to eq("preview_failed")
      expect(entry.preview_ready?).to be false
    end

    it "marks preview_failed with a truncated error when the node script fails" do
      service = described_class.new(@file)
      stub_node_thumbnail_on(service, success: false, stderr: "boom " * 200)
      service.list!
      entry = @file.archive_entries.find_by!(pathname: "parts/widget.stl")
      service.extract_mesh_and_preview!(entry)
      expect(entry.reload.status).to eq("preview_failed")
      expect(entry.preview_ready?).to be false
      expect(entry.error_message).to be_present
      expect(entry.error_message.length).to be <= 500
    end

    it "does not set preview_ready when writing a placeholder PNG" do
      service = described_class.new(@file)
      service.list!
      entry = @file.archive_entries.find_by!(pathname: "parts/widget.stl")
      dest = File.join(@library_path, "placeholder.png")
      expect {
        service.send(:write_mesh_placeholder_preview!, entry, dest)
      }.not_to change { entry.reload.status }
      expect(entry.preview_ready?).to be false
      expect(File.file?(dest)).to be true
    end

    it "raises EntryTooLarge when the mesh exceeds max extract size" do
      service = described_class.new(@file)
      service.list!
      entry = @file.archive_entries.find_by!(pathname: "parts/widget.stl")
      entry.update!(size: SiteSettings.max_file_extract_size + 1)
      expect { service.extract_mesh_and_preview!(entry) }.to raise_error(ArchiveEntryService::EntryTooLarge)
      expect(entry.reload.status).not_to eq("preview_ready")
    end

    it "raises UnsafePath when extract path is unsafe" do
      service = described_class.new(@file)
      service.list!
      entry = @file.archive_entries.find_by!(pathname: "parts/widget.stl")
      allow(service).to receive(:unsafe_pathname?).and_return(true)
      expect { service.extract_mesh_and_preview!(entry) }.to raise_error(ArchiveEntryService::UnsafePath)
    end
  end
end
