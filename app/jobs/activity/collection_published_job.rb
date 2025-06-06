class Activity::CollectionPublishedJob < ApplicationJob
  queue_as :default
  unique :until_executed

  def perform(collection_id)
    collection = Collection.find(collection_id)
    Comment.create!(
      system: true,
      commentable: collection.creator || collection,
      commenter: model.creator,
      comment: I18n.t("jobs.activity.collection_published.comment", # rubocop:disable I18n/RailsI18n/DecorateStringFormattingUsingInterpolation
        name: collection.name,
        url: collection.federails_actor.profile_url)
    )
  end
end
