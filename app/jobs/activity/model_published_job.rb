class Activity::ModelPublishedJob < ApplicationJob
  queue_as :default
  unique :until_executed

  def perform(model_id)
    model = Model.find(model_id)
    return if model.creator.nil?
    Comment.create!(
      system: true,
      commentable: model,
      commenter: model.creator,
      comment: I18n.t("jobs.activity.model_published.comment", # rubocop:disable I18n/RailsI18n/DecorateStringFormattingUsingInterpolation
        model_name: model.name,
        url: model.federails_actor.profile_url,
        tags: model.tag_list.map { |t| "##{t}" }.join(" ")),
      sensitive: model.sensitive
    )
  end
end
