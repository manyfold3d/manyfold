# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrintHost do
  describe "#unsupported_for_send?" do
    it "is false for normal SDCP hosts" do
      host = build(:print_host, name: "GK3 Pro", brand: "UniFormation")
      expect(host).not_to be_unsupported_for_send
      expect(host).to be_send_supported
    end

    it "is true for bambu / X1C decorative names" do
      expect(build(:print_host, brand: "Bambu")).to be_unsupported_for_send
      expect(build(:print_host, name: "Workbench X1C")).to be_unsupported_for_send
    end
  end

  describe "#endpoint_host_port" do
    it "formats host and port" do
      host = build(:print_host, endpoint: "http://10.0.0.199:3030")
      expect(host.endpoint_host_port).to eq("10.0.0.199:3030")
    end
  end
end
