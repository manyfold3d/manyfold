require "rails_helper"

RSpec.describe LibraryScanJob, type: :job do
  it "can scan a library directory" do
    library = create(:library, path: File.join(Rails.root, "spec", "fixtures", "library"))
    expect { LibraryScanJob.perform_now(library) }.to change { library.models.count }.to(1)
    expect(library.models.first.name).to eq "Model One"
  end
end
