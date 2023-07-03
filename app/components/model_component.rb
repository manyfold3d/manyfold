# frozen_string_literal: true

class ModelComponent < ViewComponent::Base
  def initialize(model:)
    @model = model
  end
end
