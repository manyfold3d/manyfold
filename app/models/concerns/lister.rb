module Lister
  extend ActiveSupport::Concern

  included do
    acts_as_favoritor
  end

  def list(object, list_name)
    favorite(object, scope: list_name)
  end

  def delist(object, list_name)
    unfavorite(object, scope: list_name)
  end

  def set_list_state(object, list_name, listed)
    if listed
      list(object, list_name)
    else
      delist(object, list_name)
    end
  end

  def listed?(object, list_name)
    favorited?(object, scope: list_name)
  end
end
