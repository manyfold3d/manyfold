# frozen_string_literal: true

require "rails_helper"

# Request-level smoke covering fleet → add → monitor (system driver needs Devise helpers
# that are only wired for :request in this app).
RSpec.describe "Print Studio smoke", type: :request do
  context "when signed in as administrator", :as_administrator do
    before do
      allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(false)
    end

    it "covers fleet → add → monitor HTML paths" do
      host = create(:print_host, name: "GK3 Pro — garage")
      service = instance_double(Print::SdcpService, normalized_status: {
        current_layer: 0, total_layers: 0
      })
      allow_any_instance_of(PrintHost).to receive(:service).and_return(service) # rubocop:disable RSpec/AnyInstance

      get printers_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Printers")
      expect(response.body).to include("GK3 Pro — garage")

      get new_printer_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Add a printer")
      expect(response.body).to include("Register manually")

      get printer_path(host)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("GK3 Pro — garage")
      expect(response.body).to include("Pause")
    end
  end
end
