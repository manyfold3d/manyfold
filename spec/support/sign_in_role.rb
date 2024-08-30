RSpec.configure do |config|
  config.before(:each, :as_administrator) do
    sign_in create(:admin)
  end

  config.before(:each, :as_moderator) do
    sign_in create(:moderator)
  end

  config.before(:each, :as_contributor) do
    sign_in create(:contributor)
  end

  config.before(:each, :as_viewer) do
    sign_in create(:user)
  end
end
