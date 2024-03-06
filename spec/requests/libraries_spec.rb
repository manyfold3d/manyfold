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
  context "when signed out" do
    it "needs testing"
  end

  context "when signed in" do
    before do
      sign_in create(:user)
      @library = create(:library) do |library|
        create_list(:model, 2, library: library)
      end
    end

    describe "POST /libraries/:id/scan" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "needs testing"
    end

    describe "POST /libraries/scan" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "needs testing"
    end

    describe "GET /libraries" do
      it "redirects to models index" do
        get "/libraries"
        expect(response).to redirect_to("/models")
      end
    end

    describe "POST /libraries/" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "needs testing"
    end

    describe "GET /libraries/new" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "needs testing"
    end

    describe "GET /libraries/:id/edit" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "needs testing"
    end

    describe "GET /libraries/:id" do
      it "redirects to models index with library filter" do
        get "/libraries/1"
        expect(response).to redirect_to("/models?library=1")
      end
    end

    describe "PATCH /libraries/:id" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "needs testing"
    end

    describe "DELETE /libraries/:id" do # rubocop:todo RSpec/RepeatedExampleGroupBody
      it "needs testing"
    end
  end
end
