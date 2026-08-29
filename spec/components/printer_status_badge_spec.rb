# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PrinterStatusBadge, type: :component do
  it "renders a printing badge" do
    html = render described_class.new(status: :printing)
    expect(html).to include("Printing")
    expect(html).to include("bg-success")
  end

  it "renders unsupported badge" do
    html = render described_class.new(status: :unsupported)
    expect(html).to include("Unsupported")
  end
end
