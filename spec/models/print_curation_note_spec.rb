# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrintCurationNote do
  it "belongs to a model with a body" do
    note = create(:print_curation_note, body: "Orient flat for better FEP life")
    expect(note.model).to be_present
    expect(note.body).to eq("Orient flat for better FEP life")
  end

  it "requires body" do
    expect(build(:print_curation_note, body: nil)).not_to be_valid
  end
end
