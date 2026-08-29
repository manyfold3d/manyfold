# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PrintVatCard, type: :component do
  let(:user) { create(:admin) }
  let(:host) { create(:print_host, name: "Mars 5") }
  let(:bottle) { create(:resin_bottle, brand: "Phrozen", color: "Aqua") }
  let(:vat) { create(:print_vat, print_host: host, identity: "Vat C", resin_bottle: bottle, fep_cycles: 400) }

  before do
    sign_in user
    allow(controller).to receive(:policy).and_call_original
    allow(controller).to receive(:policy).with(vat).and_return(
      instance_double(PrintVatPolicy, update?: true)
    )
  end

  it "renders identity, assignment, and FEP warning health" do
    html = render described_class.new(vat: vat, bottles: [bottle])
    expect(html).to include("Vat C")
    expect(html).to include("Mars 5")
    expect(html).to include("Phrozen Aqua")
    expect(html).to include("FEP warning").or include("Danger")
    expect(html).to include("Swap vat allocation")
  end
end
