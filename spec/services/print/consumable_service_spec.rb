# frozen_string_literal: true

require "rails_helper"

RSpec.describe Print::ConsumableService do
  subject(:service) { described_class.new(actor: actor) }

  let(:actor) { create(:admin) }
  let(:print_host) { create(:print_host, :with_capabilities) }

  before do
    allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(false)
  end

  describe "#adjust_bottle!" do
    let(:bottle) { create(:resin_bottle, print_host: print_host, remaining_ml: 500, capacity_ml: 1000) }

    it "sets remaining ml" do
      service.adjust_bottle!(bottle, remaining_ml: 420)
      expect(bottle.reload.remaining_ml).to eq(420)
    end

    it "rejects over-capacity" do
      expect {
        service.adjust_bottle!(bottle, remaining_ml: 2000)
      }.to raise_error(Print::ConsumableService::Error)
    end
  end

  describe "#record_vat_maintenance!" do
    let(:vat) { create(:print_vat, print_host: print_host, fep_cycles: 10) }

    it "increments fep cycles and syncs host" do
      service.record_vat_maintenance!(vat, increment_fep: 1)
      expect(vat.reload.fep_cycles).to eq(11)
      expect(print_host.reload.fep_cycles).to eq(11)
    end
  end
end
