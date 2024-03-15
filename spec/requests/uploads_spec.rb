require "rails_helper"

#  uploads GET    /uploads(.:format)                                                      uploads#index
#          POST   /uploads(.:format)                                                      uploads#create

RSpec.describe "Uploads" do
  context "when signed out" do
    it "needs testing when multiuser is enabled"
  end

  context "when signed in" do
    describe "GET /uploads" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "needs testing"
    end

    describe "POST /uploads" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "needs testing"
    end
  end
end
