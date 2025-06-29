# frozen_string_literal: true

class Upgrade::FixParentCollections < ApplicationJob
  queue_as :low
  unique :until_executed

  def perform
    Collection.where("id = collection_id").update_all(collection_id: nil) # rubocop:disable Rails/SkipsModelValidations
  end
end
