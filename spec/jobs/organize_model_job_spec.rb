require "rails_helper"

RSpec.describe OrganizeModelJob do
  subject(:job) { described_class.new }

  let(:model) { create(:model) }

  it "should call organise"
end
