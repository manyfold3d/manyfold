require "rails_helper"

#   scan_library POST   /libraries/:id/scan(.:format)                                           libraries#scan
# scan_libraries POST   /libraries/scan(.:format)                                               libraries#scan_all
#      libraries GET    /libraries(.:format)                                                    libraries#index
#                POST   /libraries(.:format)                                                    libraries#create
#    new_library GET    /libraries/new(.:format)                                                libraries#new
#   edit_library GET    /libraries/:id/edit(.:format)                                           libraries#edit
#        library GET    /libraries/:id(.:format)                                                libraries#show
#                PATCH  /libraries/:id(.:format)                                                libraries#update
#                PUT    /libraries/:id(.:format)                                                libraries#update
#                DELETE /libraries/:id(.:format)                                                libraries#destroy

RSpec.describe "Libraries" do
  before do
    sign_in create(:user)
    @library = create(:library) do |library|
      create_list(:model, 2, library: library)
    end
  end

  describe "GET /libraries" do
    it "redirects to models index" do
      get "/libraries"
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /libraries/1" do
    it "redirects to models index with library filter" do
      get "/libraries/1"
      expect(response).to have_http_status(:redirect)
    end
  end
end
