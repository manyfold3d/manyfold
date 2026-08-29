class Activity::ModelUpdatedJob < ApplicationJob
  queue_as :default
  unique :until_executed

  def perform(model_id)
    model = Model.find(model_id)
    Comment.create!(
      system: true,
      commentable: model,
      commenter: model.creator || model,
      comment: I18n.t("jobs.activity.updated_model.comment", # rubocop:disable I18n/RailsI18n/DecorateStringFormattingUsingInterpolation
        name: model.name,
        url: model_comment_url(model)),
      sensitive: model.sensitive
    )
  end

  private

  def model_comment_url(model)
    model.federails_actor&.profile_url || Rails.application.routes.url_helpers.model_url(model)
  end
end
