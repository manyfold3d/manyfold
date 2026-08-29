# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Print consumables and storage API" do
  let(:print_host) { create(:print_host, :with_capabilities) }
  let(:sdcp) { instance_double(Print::SdcpService) }

  context "when signed in", :as_contributor do
    it "denies resin bottle index" do
      get resin_bottles_path, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "denies storage list" do
      get printer_storage_files_path(print_host), as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when signed in", :as_administrator do
    before do
      allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(false)
    end

    it "adjusts resin bottle remaining_ml" do
      bottle = create(:resin_bottle, :assigned, print_host: print_host, remaining_ml: 500)
      patch resin_bottle_path(bottle), params: {resin_bottle: {remaining_ml: 400}}, as: :json
      expect(response).to have_http_status(:success)
      expect(bottle.reload.remaining_ml).to eq(400)
    end

    it "records vat maintenance" do
      vat = create(:print_vat, print_host: print_host, fep_cycles: 10)
      post record_maintenance_print_vat_path(vat), params: {increment_fep: 1}, as: :json
      expect(response).to have_http_status(:success)
      expect(vat.reload.fep_cycles).to eq(11)
      expect(print_host.reload.fep_cycles).to eq(11)
    end

    it "lists and deletes storage files when authorized" do
      allow(Print::SdcpService).to receive(:new).and_return(sdcp)
      allow(sdcp).to receive(:list_files).and_return([{name: "a.ctb", path: "/local/a.ctb"}])
      allow(sdcp).to receive(:storage_free_bytes).and_return(1_000_000)
      allow(sdcp).to receive(:delete_files).and_return({"Ack" => 0})

      get printer_storage_files_path(print_host), as: :json
      expect(response).to have_http_status(:success)
      expect(response.parsed_body["files"].first["name"]).to eq("a.ctb")

      delete printer_storage_files_path(print_host), params: {file_list: ["/local/a.ctb"]}, as: :json
      expect(response).to have_http_status(:no_content)
      expect(sdcp).to have_received(:delete_files).with(hash_including(file_list: ["/local/a.ctb"]))
    end

    it "rejects STL upload to printer storage with gate-style reasons" do
      tmp = Tempfile.new(["part", ".stl"])
      tmp.write("mesh")
      tmp.rewind
      file = Rack::Test::UploadedFile.new(tmp.path, "model/stl", original_filename: "part.stl")
      post printer_storage_files_path(print_host), params: {file: file}
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to eq("unsupported_file_type")
      expect(response.parsed_body["reasons"].first["code"]).to eq("format_unsupported")
    ensure
      tmp&.close!
    end
  end
end
