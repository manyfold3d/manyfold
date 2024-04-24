# frozen_string_literal: true

class ModelComponent < ViewComponent::Base
  def initialize(model:, can_show: false, can_edit: false, can_destroy: false)
    @model = model
    @can_destroy = can_destroy
    @can_show = can_show
    @can_edit = can_edit
  end
end
