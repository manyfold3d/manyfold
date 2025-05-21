# frozen_string_literal: true

class Components::Link < Components::BaseButton
  include Phlex::Rails::Helpers::LinkTo

  def helper(*args)
    link_to(*args) { yield }
  end
end
