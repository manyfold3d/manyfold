require "rails_helper"

describe Doorkeeper::ApplicationPolicy do
  subject(:policy) { described_class }

  let(:owner) { create(:contributor) }
  let(:other_user) { create(:contributor) }
  let(:admin) { create(:admin) }
  let(:application) { create(:oauth_application, owner: owner) }

  permissions :update?, :destroy? do
    it "allows the owner" do
      expect(policy).to permit(owner, application)
    end

    it "allows administrators" do
      expect(policy).to permit(admin, application)
    end

    it "denies non-owners" do
      expect(policy).not_to permit(other_user, application)
    end
  end
end
