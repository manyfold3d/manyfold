# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Printer settings HTML UI" do
  context "when signed in", :as_administrator do
    before do
      allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(false)
    end

    it "renders identity, storage, gate checklist, and camera" do
      host = create(:print_host, :with_capabilities, name: "GK3 Pro — garage")
      service = instance_double(Print::SdcpService,
        normalized_status: {filename: nil},
        list_files: [{name: "plate.ctb", path: "/local/plate.ctb", size: 1_024_000}],
        storage_free_bytes: 2_000_000_000)
      allow_any_instance_of(PrintHost).to receive(:service).and_return(service) # rubocop:disable RSpec/AnyInstance

      get settings_printer_path(host)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Machine Identity")
      expect(response.body).to include("On-board Storage")
      expect(response.body).to include("Compatibility Gate")
      expect(response.body).to include("Camera Enclosure")
      expect(response.body).to include("plate.ctb")
      expect(response.body).to include("UniFormation")
      expect(response.body).to include(snapshot_printer_path(host))
    end

    it "updates identity fields via HTML" do
      host = create(:print_host, :with_capabilities)
      patch printer_path(host), params: {printer: {brand: "UpdatedBrand", firmware: "9.9.9"}}
      expect(response).to redirect_to(settings_printer_path(host))
      expect(host.reload.brand).to eq("UpdatedBrand")
      expect(host.firmware).to eq("9.9.9")
    end

    it "uploads sliced storage file via HTML form" do
      host = create(:print_host, :with_capabilities)
      service = instance_double(Print::SdcpService)
      allow(Print::SdcpService).to receive(:new).and_return(service)
      allow(service).to receive(:upload).and_return({"Ack" => 0})

      tmp = Tempfile.new(["plate", ".ctb"])
      tmp.write("sliced")
      tmp.rewind
      file = Rack::Test::UploadedFile.new(tmp.path, "application/octet-stream", original_filename: "plate.ctb")
      post printer_storage_files_path(host), params: {file: file}
      expect(response).to redirect_to(settings_printer_path(host))
      expect(service).to have_received(:upload)
    ensure
      tmp&.close!
    end

    it "deletes storage file via HTML form" do
      host = create(:print_host, :with_capabilities)
      service = instance_double(Print::SdcpService)
      allow(Print::SdcpService).to receive(:new).and_return(service)
      allow(service).to receive(:delete_files).and_return({"Ack" => 0})

      delete printer_storage_files_path(host), params: {file_list: ["/local/a.ctb"]}
      expect(response).to redirect_to(settings_printer_path(host))
      expect(service).to have_received(:delete_files).with(hash_including(file_list: ["/local/a.ctb"]))
    end
  end

  context "when signed in", :as_contributor do
    it "forbids settings HTML" do
      host = create(:print_host)
      get settings_printer_path(host)
      expect(response).to have_http_status(:forbidden).or have_http_status(:not_found)
    end
  end
end
