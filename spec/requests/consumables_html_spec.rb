# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consumables HTML UI" do
  context "when signed in", :as_administrator do
    before do
      allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(false)
    end

    it "renders resin inventory, maintenance table, and vat registry" do
      host = create(:print_host, :with_capabilities, name: "Saturn 4 Ultra", fep_cycles: 400, lcd_hours: 1800)
      bottle = create(:resin_bottle, :assigned, print_host: host, brand: "Elegoo", color: "Standard Grey",
        remaining_ml: 200, capacity_ml: 1000)
      create(:print_vat, print_host: host, identity: "Vat A - Grey", resin_bottle: bottle, fep_cycles: 400)

      get consumables_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Consumables")
      expect(response.body).to include("Elegoo Standard Grey")
      expect(response.body).to include("Saturn 4 Ultra")
      expect(response.body).to include("Vat A - Grey")
      expect(response.body).to include("WARNING").or include("Warning").or include("Danger")
      expect(response.body).to include("Low")
    end

    it "adjusts resin bottle remaining_ml via HTML form" do
      bottle = create(:resin_bottle, remaining_ml: 500, capacity_ml: 1000)
      patch resin_bottle_path(bottle), params: {resin_bottle: {remaining_ml: 350}}
      expect(response).to redirect_to(consumables_path)
      expect(bottle.reload.remaining_ml).to eq(350)
    end

    it "swaps vat resin allocation" do
      host = create(:print_host)
      bottle = create(:resin_bottle, brand: "Siraya", color: "Fast")
      vat = create(:print_vat, print_host: host, resin_bottle: nil)
      post swap_print_vat_path(vat), params: {resin_bottle_id: bottle.id}
      expect(response).to redirect_to(consumables_path)
      expect(vat.reload.resin_bottle_id).to eq(bottle.id)
    end
  end

  context "when signed in", :as_contributor do
    it "forbids consumables HTML" do
      get consumables_path
      expect(response).to have_http_status(:forbidden).or have_http_status(:not_found)
    end
  end
end
