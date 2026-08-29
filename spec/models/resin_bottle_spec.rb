# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResinBottle do
  it "persists brand, color, remaining, capacity, opened_on" do
    bottle = create(:resin_bottle,
      brand: "Siraya Tech",
      color: "Build",
      remaining_ml: 400,
      capacity_ml: 1000,
      opened_on: Date.new(2026, 8, 1))
    expect(bottle.brand).to eq("Siraya Tech")
    expect(bottle.color).to eq("Build")
    expect(bottle.remaining_ml).to eq(400)
    expect(bottle.capacity_ml).to eq(1000)
    expect(bottle.opened_on).to eq(Date.new(2026, 8, 1))
  end

  it "allows nullable print_host" do
    expect(create(:resin_bottle, print_host: nil).print_host).to be_nil
  end

  it "can be assigned to a print_host" do
    bottle = create(:resin_bottle, :assigned)
    expect(bottle.print_host).to be_a(PrintHost)
  end

  it "rejects remaining above capacity" do
    expect(build(:resin_bottle, remaining_ml: 1200, capacity_ml: 1000)).not_to be_valid
  end

  it "requires brand" do
    expect(build(:resin_bottle, brand: nil)).not_to be_valid
  end
end
