class Activity::CreatorAddedModelJob < ApplicationJob
  queue_as :activity

  def perform(model_id)
  end
end
