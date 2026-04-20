class Activity::ModelUpdatedJob < ApplicationJob
  queue_as :default
  unique :until_executed

  def perform(model_id)
    model = Model.find(model_id)
    Comment.create!(
      system: true,
      commentable: model,
      commenter: model.creator || model,
      comment: I18n.t("jobs.activity.updated_model.comment",
        name: model.name,
        url: model.federails_actor.profile_url,
        creator_handle: model.creator.federails_actor.at_address,
        creator_name: model.creator.name),
      sensitive: model.sensitive
    )
  end
end
