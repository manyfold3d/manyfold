require "rails_helper"

RSpec.describe FileHandlers do
  it "autoloads file handlers" do
    expect(FileHandlers::ALL_HANDLERS).not_to be_empty
  end
end
