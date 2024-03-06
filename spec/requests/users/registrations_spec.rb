require "rails_helper"

# cancel_user_registration GET    /users/cancel(.:format)                                                 users/registrations#cancel
#    new_user_registration GET    /users/sign_up(.:format)                                                users/registrations#new
#   edit_user_registration GET    /users/edit(.:format)                                                   users/registrations#edit
#        user_registration PATCH  /users(.:format)                                                        users/registrations#update
#                          PUT    /users(.:format)                                                        users/registrations#update
#                          DELETE /users(.:format)                                                        users/registrations#destroy
#                          POST   /users(.:format)                                                        users/registrations#create

RSpec.describe "Users::Registrations" do
  context "when signed out" do # rubocop:todo RSpec/RepeatedExampleGroupBody
    it "needs testing"
  end

  context "when signed in" do # rubocop:todo RSpec/RepeatedExampleGroupBody
    it "needs testing"
  end
end
