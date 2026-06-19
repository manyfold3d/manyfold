module SignInHelpers
  def current_user
    @current_user.reload
  end
end

RSpec.configure do |config|
  config.include SignInHelpers, type: :request

  config.before(:each, :as_administrator) do
    @current_user = create(:admin)
    sign_in @current_user
  end

  config.before(:each, :as_moderator) do
    @current_user = create(:moderator)
    sign_in @current_user
  end

  config.before(:each, :as_contributor) do
    @current_user = create(:contributor)
    sign_in @current_user
  end

  config.before(:each, :as_member) do
    @current_user = create(:user)
    sign_in @current_user
  end

  config.before(:each, :as_printer) do
    @current_user = create(:printer)
    sign_in @current_user
  end
end
