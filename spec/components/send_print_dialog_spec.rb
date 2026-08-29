# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::SendPrintDialog, type: :component do
  let(:model) { create(:model) }
  let(:file) { create(:model_file, model: model, filename: "helmet.ctb") }
  let(:printer) { create(:print_host, :with_capabilities, name: "GK3") }

  before do
    policy_double = instance_double(PrintHostPolicy, control?: true, index?: true)
    allow(controller).to receive(:policy).and_call_original
    allow(controller).to receive(:policy).with(PrintHost).and_return(policy_double)
  end

  it "renders prepare stub disabled and sliced send path" do
    html = render described_class.new(
      model: model,
      file: file,
      printers: [printer],
      eligibility_url: "/models/#{model.to_param}/model_files/#{file.to_param}/send_eligibility"
    )
    expect(html).to include("Print this model")
    expect(html).to include("Open Prepare")
    expect(html).to include("disabled")
    expect(html).to include("Send .CTB")
  end

  it "does not render for STL files" do
    stl = create(:model_file, model: model, filename: "part.stl")
    html = render described_class.new(
      model: model,
      file: stl,
      printers: [printer],
      eligibility_url: "/x"
    )
    expect(html).to eq("")
  end
end
