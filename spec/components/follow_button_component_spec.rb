# frozen_string_literal: true

require "rails_helper"

RSpec.describe FollowButtonComponent, type: :component do
  let(:follower) { create(:user) }
  let(:target) { create(:creator) }

  before do
    sign_in(follower)
    allow(SiteSettings).to receive(:multiuser_enabled?).and_return(true)
  end

  context "when the follower is not following the target" do
    let(:button) {
      allow(follower).to receive(:following?).with(target).and_return false
      render_inline(described_class.new(follower: follower, target: target)).to_html
    }

    it "creates a button" do
      expect(button).to include "<button"
    end

    it "is labelled with the word Follow" do
      expect(button).to include "Follow"
    end

    it "links to the create path for the target's follows resource" do # rubocop:todo RSpec/MultipleExpectations
      expect(button).to include "method=\"post\""
      expect(button).to include "action=\"/creators/#{target.to_param}/follows\""
    end
  end

  context "when the follower is already following the target" do
    let(:button) {
      allow(follower).to receive(:following?).with(target).and_return true
      render_inline(described_class.new(follower: follower, target: target)).to_html
    }

    it "creates a button" do
      expect(button).to include "<button"
    end

    it "is labelled with the word Unfollow" do
      expect(button).to include "Unfollow"
    end

    it "links to the delete path for the target's follows resource" do # rubocop:todo RSpec/MultipleExpectations
      expect(button).to include "name=\"_method\" value=\"delete\""
      expect(button).to include "action=\"/creators/#{target.to_param}/follows\""
    end
  end
end
