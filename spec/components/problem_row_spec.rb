# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ProblemRow, type: :component do
  let(:model) { create(:model, name: "Bleach Ichigo Diorama Hq") }
  let(:file) { create(:model_file, model: model, filename: "ichigo_diorama_v2_hollow.stl", size: 142.megabytes) }
  let(:problem) { create(:problem, category: :duplicate, problematic: file, note: "Photo 2020 04 01 17 05 41") }

  it "renders a full-width card row with title, file meta, and view control" do
    html = render described_class.new(problem: problem, user: nil)
    expect(html).to include("problem-row")
    expect(html).to include("Bleach Ichigo Diorama Hq")
    expect(html).to include("ichigo_diorama_v2_hollow.stl")
    expect(html).to include("142 MB")
    expect(html).to include("Photo 2020 04 01 17 05 41")
    expect(html).to include(%(id="problem-#{problem.id}"))
  end

  it "does not emit table cells" do
    html = render described_class.new(problem: problem, user: nil)
    expect(html).not_to include("<td")
    expect(html).not_to include("<tr")
  end
end
