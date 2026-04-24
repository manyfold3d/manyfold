require "rails_helper"

RSpec.describe CreateObjectFromUrlJob, :after_first_run do
  subject(:job) { described_class.new }

  before { create(:library) }

  it "creates a model if given a thingiverse URL", :thingiverse_api_key do
    expect { job.perform(url: "https://www.thingiverse.com/thing:4049220") }.to change(Model, :count).by(1)
  end

  it "creates a creator if given a thingiverse URL", :thingiverse_api_key do
    expect { job.perform(url: "https://www.thingiverse.com/floppy_uk") }.to change(Creator, :count).by(1)
  end

  it "creates a collection if given a thingiverse URL", :thingiverse_api_key do
    expect { job.perform(url: "https://www.thingiverse.com/floppy_uk/collections/16696069/things") }.to change(Collection, :count).by(1)
  end

  it "queues up metadata load job", :thingiverse_api_key do
    expect { job.perform(url: "https://www.thingiverse.com/floppy_uk") }.to have_enqueued_job(UpdateMetadataFromLinkJob).once
  end

  it "sets specified owner", :thingiverse_api_key do # rubocop:disable RSpec/MultipleExpectations
    contributor = create(:contributor)
    job.perform(url: "https://www.thingiverse.com/thing:4049220", owner: contributor)
    expect(Model.last.grants_permission_to?("own", contributor)).to be true
  end

  it "has no owner if not specified", :thingiverse_api_key do
    job.perform(url: "https://www.thingiverse.com/thing:4049220")
    expect(Model.last.owners).to be_empty
  end

  it "sets collection", :thingiverse_api_key do
    collection = create(:collection)
    job.perform(url: "https://www.thingiverse.com/thing:4049220", collection_id: collection.id)
    expect(Model.last.collections).to include collection
  end
end
