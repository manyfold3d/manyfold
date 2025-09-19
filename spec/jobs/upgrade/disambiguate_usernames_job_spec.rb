# frozen_string_literal: true

require "rails_helper"

RSpec.describe Upgrade::DisambiguateUsernamesJob do
  subject(:job) { described_class.new }

  let(:user) { create(:user, username: "conflict") }
  let(:creator) { create(:creator, :without_validations, slug: user.username) }

  it "confirms test creator is invalid" do
    expect(creator).not_to be_valid
  end

  it "detects that there is a duplicate" do
    creator.touch # rubocop:disable Rails/SkipsModelValidations
    expect(job.send(:duplicated_usernames)).to contain_exactly("conflict")
  end

  it "modifies creator name to remove duplication" do
    expect { job.perform_now }.to change { creator.reload.slug }.from("conflict").to("conflict1")
  end

  it "preserves username" do
    expect { job.perform_now }.not_to change { user.reload.username }
  end
end
