class Activity::ModelCollectedJob < ApplicationJob
  queue_as :default
  unique :until_executed

  def perform(model_id, collection_id)
    model = Model.find(model_id)
    collection = Collection.find(collection_id)
    Comment.create!(
      system: true,
      commentable: model,
      commenter: model.creator || collection || model,
      comment: I18n.t("jobs.activity.model_collected.comment", # rubocop:disable I18n/RailsI18n/DecorateStringFormattingUsingInterpolation
        model_name: model.name,
        model_url: model.federails_actor.profile_url,
        collection_name: collection.name,
        collection_url: collection.federails_actor.profile_url),
      sensitive: model.sensitive
    )
  end
end
