RSpec.configure do |config|
  config.before(:each, :as_administrator) do
    sign_in create(:admin)
  end

  config.before(:each, :as_editor) do
    sign_in create(:editor)
  end

  config.before(:each, :as_contributor) do
    sign_in create(:contributor)
  end

  config.before(:each, :as_viewer) do
    sign_in create(:user)
  end
end
