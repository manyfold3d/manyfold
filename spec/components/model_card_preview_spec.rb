# frozen_string_literal: true

# Provenance: INIT-006/SPEC-002
require "rails_helper"

RSpec.describe Components::ModelCardPreview, type: :component do
  let(:model) { create(:model, name: "Gallery Model") }
  let!(:file) { create(:model_file, model: model, filename: "cover.jpg") }

  before do
    model.update!(preview_file: file)
    allow(controller).to receive_messages(
      policy: double(edit?: false, destroy?: false, show?: true),
      current_user: nil
    )
  end

  it "opens gallery from the preview control without linking the preview to the model show" do
    html = render described_class.new(model: model.reload, editable: false, gallery: true)
    expect(html).to include("click->model-gallery#open")
    expect(html).to include("/models/#{model.to_param}/gallery")
    # Preview control is a button, not an <a href=…/models/…> wrapping the image
    expect(html).to match(/<button[^>]*data-action="click->model-gallery#open"/)
    expect(html).not_to match(%r{<a[^>]*href="[^"]*/models/#{Regexp.escape(model.to_param)}"[^>]*class="absolute inset-0})
  end

  it "falls back to a model link when gallery is disabled" do
    html = render described_class.new(model: model.reload, editable: false, gallery: false)
    expect(html).not_to include("click->model-gallery#open")
    expect(html).to include(%(/models/#{model.to_param}))
  end
end
