# frozen_string_literal: true

class Components::ModelComponent < ViewComponent::Base
  def initialize(model:, can_edit: false, can_destroy: false)
    @model = model
    @can_destroy = can_destroy
    @can_edit = can_edit
  end
end
