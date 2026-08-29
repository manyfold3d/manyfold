# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings::PrintHosts" do
  let(:attrs) {
    {
      name: "GK3 Pro",
      endpoint: "http://10.0.0.199:3030",
      mainboard_id: "d307202d8c1e0100"
    }
  }

  context "when signed out" do
    it "redirects index to sign in" do
      get settings_print_hosts_path
      expect(response).to redirect_to("/users/sign_in")
    end

    it "redirects snapshot to sign in" do
      host = create(:print_host)
      get snapshot_settings_print_host_path(host)
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  context "when signed in", :as_contributor do
    it "hides index" do
      get settings_print_hosts_path
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when signed in", :as_administrator do
    it "lists printers" do
      create(:print_host, name: "GK3 Pro")
      get settings_print_hosts_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("GK3 Pro")
    end

    it "creates an SDCP printer" do
      expect {
        post settings_print_hosts_path, params: {print_host: attrs}
      }.to change(PrintHost, :count).by(1)
      expect(response).to redirect_to(settings_print_host_path(PrintHost.last))
    end

    it "rejects public endpoints (SSRF)" do
      post settings_print_hosts_path, params: {
        print_host: attrs.merge(endpoint: "http://1.1.1.1:3030")
      }
      expect(PrintHost.where(endpoint: "http://1.1.1.1:3030")).to be_empty
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "proxies snapshot only when authorized" do
      host = create(:print_host)
      allow(Print::Go2rtcClient).to receive(:frame_jpeg).and_return("\xFF\xD8\xFF" + ("x" * 200))
      get snapshot_settings_print_host_path(host)
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("image/jpeg")
    end
  end
end
