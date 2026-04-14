class ListItem < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.list_item")

  belongs_to :list
  belongs_to :listable, polymorphic: true
end
