class ListItem < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.list_item")

  belongs_to :list
  belongs_to :listable, polymorphic: true

  after_create -> do
    listable.update_like_count! if list.special == "liked"
  end
end
