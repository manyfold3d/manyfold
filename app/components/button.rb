# frozen_string_literal: true

class Components::Button < Components::BaseButton
  include Phlex::Rails::Helpers::ButtonTo

  def helper(*args)
    button_to(*args) { yield }
  end
end
