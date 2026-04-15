class ListItem < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.list_item")

  belongs_to :list
  belongs_to :listable, polymorphic: true

  after_create :update_likes, if: -> { list.special == "liked" }

  private

  def update_likes
    if SiteSettings.federation_enabled? && listable.public?
      listable.federails_actor.like! actor: list.owner.federails_actor
      listable.creation_comment.try(:like!, actor: list.owner.federails_actor)
    end
    listable.update_like_count!
  end
end
