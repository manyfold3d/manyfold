# frozen_string_literal: true

require "rails_helper"

describe PrintHostPolicy do
  subject(:policy) { described_class }

  let(:print_host) { build(:print_host) }
  let(:admin) { create(:admin) }
  let(:member) { create(:user) }

  permissions :index?, :show? do
    it "allows administrators" do
      expect(policy).to permit(admin, print_host)
    end

    it "denies members" do
      expect(policy).not_to permit(member, print_host)
    end
  end

  permissions :create?, :update?, :destroy?, :control? do
    it "allows administrators when demo mode is off" do
      allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(false)
      expect(policy).to permit(admin, print_host)
    end

    it "denies administrators in demo mode" do
      allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(true)
      expect(policy).not_to permit(admin, print_host)
    end

    it "denies members" do
      allow(SiteSettings).to receive(:demo_mode_enabled?).and_return(false)
      expect(policy).not_to permit(member, print_host)
    end
  end
end
