module PhlexTestHelpers
  def render(...)
    view_context.render(...)
  end

  delegate :view_context, to: :controller

  def controller
    @controller ||= ActionView::TestCase::TestController.new
  end

  def sign_in(user)
    allow(controller).to receive(:current_user).and_return(user)
  end
end

RSpec.configure do |config|
  config.include PhlexTestHelpers, type: :component
end
