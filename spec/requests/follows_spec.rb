require "rails_helper"

RSpec.describe "Follows" do
  describe "POST /create" do
    it "should add a follow relationship for current user"
    it "should not add another follow relationship if one already exists"
  end

  describe "DELETE /" do
    it "should remove a follow relationship for current user"
    it "should work even if current user is not following target"
  end
end
