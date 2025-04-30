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

  it "must have a valid url" do
    model = create(:model, links_attributes: [{url: ""}])
    expect(model.links).to be_empty
  end

  it "must be unique per linkable thing" do
    url = "https://www.example.com"
    model = create(:model, links_attributes: [{url: url}])
    duplicate = described_class.new(linkable: model, url: url)
    expect(duplicate).not_to be_valid
  end

  it "allows same URL in different linkable things" do
    url = "https://www.example.com"
    create(:model, links_attributes: [{url: url}])
    model2 = create(:model)
    duplicate = described_class.new(linkable: model2, url: url)
    expect(duplicate).to be_valid
  end
end
