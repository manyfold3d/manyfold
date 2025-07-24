require "rails_helper"

#    imports POST   /imports(.:format)                                     imports#create
# new_import GET    /imports/new(.:format)                                 imports#new
RSpec.describe "Imports", :after_first_run, :thingiverse_api_key do
  context "when signed out in multiuser mode", :multiuser

  [:multiuser, :singleuser].each do |mode|
    context "when signed in in #{mode} mode", mode do
      describe "POST /imports", :as_contributor do
        let(:url) { "https://thingiverse.com/thing:1234" }
        let(:import) { post "/imports", params: {url: url} }

        it "redirects back afterwards" do
          import
          expect(response).to redirect_to("/")
        end

        it "queues creation job with correct arguments" do
          expect { import }.to have_enqueued_job(CreateObjectFromUrlJob).with(
            url: url,
            owner: User.with_role(:contributor).first
          )
        end
      end
    end
  end
end
