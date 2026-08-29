# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrintVat do
  let(:print_host) { create(:print_host) }

  it "persists identity, fep_cycles, host, resin, and status" do
    bottle = create(:resin_bottle)
    vat = create(:print_vat,
      print_host: print_host,
      resin_bottle: bottle,
      identity: "Front vat",
      fep_cycles: 200,
      status: :in_use)
    expect(vat.identity).to eq("Front vat")
    expect(vat.fep_cycles).to eq(200)
    expect(vat.print_host).to eq(print_host)
    expect(vat.resin_bottle).to eq(bottle)
    expect(vat).to be_in_use
  end

  it "requires identity unique per host" do
    create(:print_vat, print_host: print_host, identity: "A")
    expect(build(:print_vat, print_host: print_host, identity: "A")).not_to be_valid
  end

  it "allows same identity on different hosts" do
    create(:print_vat, print_host: print_host, identity: "A")
    other = create(:print_host, endpoint: "http://10.0.0.202:3030", mainboard_id: "deadbeefcafebabe")
    expect(create(:print_vat, print_host: other, identity: "A")).to be_valid
  end

  it "rejects negative fep_cycles" do
    expect(build(:print_vat, print_host: print_host, fep_cycles: -1)).not_to be_valid
  end
end
