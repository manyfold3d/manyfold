# frozen_string_literal: true

require "rails_helper"

# INIT-022/SPEC-010 — Scan dropdown Dedup item (navbar only).
RSpec.describe "Navbar Scan Dedup" do
  let(:dedup_label) { I18n.t("application.navbar.dedup.label") }
  let(:dedup_confirm) { I18n.t("application.navbar.dedup.confirm") }

  context "when administrator", :as_administrator do
    it "includes Dedup posting scans_path(type: :dedup) with review-only confirm" do
      get "/settings"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(dedup_label)
      expect(response.body).to include("/scans?type=dedup")
      expect(response.body).to include(dedup_confirm)
      expect(response.body).to match(/data-(?:turbo-)?method="post"/)
      expect(dedup_confirm).to match(/review/i)
      expect(dedup_confirm).to match(/not(?:hing)? is merged automatically/i)
    end
  end

  context "when moderator", :as_moderator do
    it "omits Dedup because scan create is admin-only" do
      get "/problems/index"
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("/scans?type=dedup")
      expect(response.body).not_to include(dedup_label)
    end
  end

  context "when signed out", :after_first_run, :multiuser do
    it "omits Dedup" do
      get "/users/sign_in"
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("/scans?type=dedup")
      expect(response.body).not_to include(">#{dedup_label}<")
    end
  end
end
