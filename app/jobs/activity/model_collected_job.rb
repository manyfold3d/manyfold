class Activity::ModelCollectedJob < ApplicationJob
  queue_as :default
  unique :until_executed

  def perform(model_id, collection_id)
    model = Model.find(model_id)
    collection = model.collections.find(collection_id)
    # Make sure the model is still in the collection, this could be later on
    return unless collection
    # Boost the new model and its creation comment to the collection's followers
    model.federails_actor.announce! actor: collection.federails_actor
    model.creation_comment.announce! actor: collection.federails_actor
  end
end
