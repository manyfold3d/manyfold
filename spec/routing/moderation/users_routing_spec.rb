require "rails_helper"

RSpec.describe Settings::UsersController do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/settings/users").to route_to("settings/users#index")
    end

    it "routes to #show" do
      expect(get: "/settings/users/1").to route_to("settings/users#show", id: "1")
    end
  end
end
