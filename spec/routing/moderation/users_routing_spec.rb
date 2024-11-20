require "rails_helper"

RSpec.describe Settings::UsersController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/settings/users").to route_to("settings/users#index")
    end
  end
end
