# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::CompatibilityChecklist, type: :component do
  it "renders pass and fail rules with icons" do
    rules = [
      {key: :formats, pass: true, title: "File type formats", detail: "Matches .ctb"},
      {key: :aa, pass: false, title: "Slicing AA check", detail: "AA unknown"}
    ]
    html = render described_class.new(rules: rules)
    expect(html).to include("File type formats")
    expect(html).to include("Slicing AA check")
    expect(html).to include("bi-check-circle-fill")
    expect(html).to include("bi-x-circle-fill")
  end
end
