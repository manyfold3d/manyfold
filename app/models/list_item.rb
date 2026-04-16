class ListItem < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.list_item")

  belongs_to :list
  belongs_to :listable, polymorphic: true

  after_create :update_likes, if: -> { list.special == "liked" }

  private

  def update_likes
    if SiteSettings.federation_enabled? && listable.public?
      if (actor = list.owners&.first&.federails_actor)
        listable.federails_actor.like! actor: actor
        listable.creation_comment.try(:like!, actor: actor)
      end
    end
    listable.update_like_count!
  end
end
