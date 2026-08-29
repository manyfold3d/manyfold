# frozen_string_literal: true

require "rails_helper"

describe PrintJobPolicy do
  subject(:policy) { described_class }

  let(:print_job) { build(:print_job) }
  let(:admin) { create(:admin) }
  let(:member) { create(:user) }

  permissions :index?, :show? do
    it "allows administrators" do
      expect(policy).to permit(admin, print_job)
    end

    it "denies members" do
      expect(policy).not_to permit(member, print_job)
    end
  end

  permissions :create?, :start?, :pause?, :resume?, :cancel?, :confirm_plate_cleared?, :control? do
    it "allows administrators when demo mode is off" do
      allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(false)
      expect(policy).to permit(admin, print_job)
    end

    it "denies in demo mode" do
      allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(true)
      expect(policy).not_to permit(admin, print_job)
    end

    it "denies members" do
      allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(false)
      expect(policy).not_to permit(member, print_job)
    end
  end
end
