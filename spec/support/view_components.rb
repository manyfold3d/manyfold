require "view_component/test_helpers"
require "view_component/system_test_helpers"

# For devise in viewcomponents: https://github.com/ViewComponent/view_component/discussions/371
module ManyfoldViewComponentTestHelpers
  include ViewComponent::TestHelpers
  def sign_in(user)
    allow(vc_test_controller).to receive(:current_user).and_return(user)
  end
end

RSpec.configure do |config|
  config.include ManyfoldViewComponentTestHelpers, type: :component
  config.include ViewComponent::SystemTestHelpers, type: :component
end
