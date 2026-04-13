# frozen_string_literal: true

class Favorite < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.favorite")

  extend ActsAsFavoritor::FavoriteScopes

  belongs_to :favoritable, polymorphic: true
  belongs_to :favoritor, polymorphic: true

  def block!
    update!(blocked: true)
  end
end
