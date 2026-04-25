# frozen_string_literal: true

class Upgrade::ConvertCollectionsJob < ApplicationJob
  queue_as :low
  unique :until_executed

  def perform
    # Find models that have something in the old collection field
    Model.where.not(collection_id: nil).find_each do |model|
      collection = Collection.find(model.collection_id)
      # Add to the new association
      model.collections << collection unless model.collections.include?(collection)
      # Remove the old collection ID
      model.collection_id = nil
      model.save(validate: false, touch: false)
    end
  end
end
