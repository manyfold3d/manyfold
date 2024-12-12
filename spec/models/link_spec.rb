require "rails_helper"
RSpec.describe Link do
  it "extracts site name from domain" do
    link = described_class.new(url: "https://www.example.com")
    expect(link.site).to eq "example"
  end

  it "extracts site fails safe with bad domain" do
    link = described_class.new(url: "https://boop")
    expect(link.site).to eq "boop"
  end
end
