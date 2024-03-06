require "rails_helper"

#     creators GET    /creators(.:format)                                                     creators#index
#              POST   /creators(.:format)                                                     creators#create
#  new_creator GET    /creators/new(.:format)                                                 creators#new
# edit_creator GET    /creators/:id/edit(.:format)                                            creators#edit
#      creator GET    /creators/:id(.:format)                                                 creators#show
#              PATCH  /creators/:id(.:format)                                                 creators#update
#              PUT    /creators/:id(.:format)                                                 creators#update
#              DELETE /creators/:id(.:format)                                                 creators#destroy

RSpec.describe "Creators" do
  before do
    sign_in create(:user)
    build_list(:creator, 13) do |creator|
      creator.save! # See https://dev.to/hernamvel/the-optimal-way-to-create-a-set-of-records-with-factorybot-createlist-factorybot-buildlist-1j64
      create_list(:link, 1, linkable: creator)
      create_list(:model, 1, creator: creator)
    end
  end

  describe "GET /creators?page=2" do
    it "returns paginated creators" do # rubocop:todo RSpec/MultipleExpectations
      get "/creators?page=2"
      expect(response).to have_http_status(:success)
      expect(response.body).to match(/pagination/)
    end
  end
end
