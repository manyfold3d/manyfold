# frozen_string_literal: true

# Provenance: INIT-006/SPEC-002
require "rails_helper"

RSpec.describe Components::ImageCarousel, type: :component do
  let(:model) { create(:model) }
  let!(:preview) { create(:model_file, model: model, filename: "a.jpg") }
  let!(:second) { create(:model_file, model: model, filename: "b.jpg") }

  before do
    model.update!(preview_file: preview)
    allow(controller).to receive(:policy).and_return(double(edit?: false, destroy?: false))
  end

  it "renders browse carousel with prev/next when two or more images" do
    html = render described_class.new(images: [preview, second], browse: true)
    expect(html).to include('id="browseCarousel"')
    expect(html).to include('data-carousel-interval-value="0"')
    expect(html).to include("object-contain")
    expect(html).to include("carousel#prev")
    expect(html).to include("carousel#next")
    expect(html).to include("carousel-item")
  end

  it "omits prev/next for a single browse image" do
    html = render described_class.new(images: [preview], browse: true)
    expect(html).to include('id="browseCarousel"')
    expect(html).not_to include("carousel#prev")
    expect(html).not_to include("carousel#next")
  end
end
