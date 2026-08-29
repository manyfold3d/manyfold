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
        model_url: entity_comment_url(model),
        collection_name: collection.name,
        collection_url: entity_comment_url(collection)),
      sensitive: model.sensitive
    )
  end

  private

  def entity_comment_url(entity)
    entity.federails_actor&.profile_url || Rails.application.routes.url_helpers.url_for(entity)
  end
end
