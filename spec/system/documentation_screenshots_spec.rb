require "rails_helper"

RSpec.describe "Documentation screenshots", :documentation do
  before do
    driven_by :selenium
  end

  describe "home page" do
    it "contains things" do
      visit "/"

      inputs = find_all "input"
      inject_outlines inputs
      inject_dots inputs

      take_and_crop_screenshot "home_page"
    end
  end
end
