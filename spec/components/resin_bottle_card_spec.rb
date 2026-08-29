# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ResinBottleCard, type: :component do
  let(:user) { create(:admin) }
  let(:bottle) {
    create(:resin_bottle, brand: "Elegoo", color: "Grey", remaining_ml: 200, capacity_ml: 1000)
  }

  before do
    sign_in user
    allow(controller).to receive(:policy).and_call_original
    allow(controller).to receive(:policy).with(bottle).and_return(
      instance_double(ResinBottlePolicy, update?: true)
    )
  end

  it "renders brand, volume, and low warning" do
    html = render described_class.new(bottle: bottle)
    expect(html).to include("Elegoo Grey")
    expect(html).to include("200ml")
    expect(html).to include("Low")
    expect(html).to include("Adjust level")
  end
end
