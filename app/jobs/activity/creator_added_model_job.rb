class Activity::CreatorAddedModelJob < ApplicationJob
  queue_as :activity

  def perform(model_id)
    model = Model.find(model_id)
    Comment.create!(
      system: true,
      commentable: model,
      commenter: model.creator,
      comment: I18n.t("jobs.activity.creator_added_model.comment", # rubocop:disable I18n/RailsI18n/DecorateStringFormattingUsingInterpolation
        model_name: model.name,
        url: model.actor.profile_url,
        tags: model.tag_list.map { |t| "##{t}" }.join(" ")),
      sensitive: model.sensitive
    )
  end
end
