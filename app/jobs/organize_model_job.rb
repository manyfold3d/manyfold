class OrganizeModelJob < ApplicationJob
  queue_as :default

  def perform(model_id)
    model = Model.find(model_id)
    model&.organize!
  end

end
