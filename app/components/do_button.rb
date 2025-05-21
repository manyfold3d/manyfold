# frozen_string_literal: true

class Components::DoButton < Components::BaseButton
  include Phlex::Rails::Helpers::ButtonTo

  def helper(*args)
    button_to(*args) { yield }
  end
end
