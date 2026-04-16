class Activity::ModelPublishedJob < ApplicationJob
  queue_as :default
  unique :until_executed

  def perform(model_id)
    model = Model.find(model_id)
    Comment.create!(
      system: true,
      commentable: model,
      commenter: model.creator || model,
      comment: I18n.t("jobs.activity.model_published.comment", # rubocop:disable I18n/RailsI18n/DecorateStringFormattingUsingInterpolation
        name: model.name,
        creator_handle: model.creator.federails_actor.at_address),
      sensitive: model.sensitive
    )
  end
end
