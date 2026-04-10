module Likeable
  extend ActiveSupport::Concern

  def like_count
    list_items.includes(:list).where("list.special": :liked).count
  end
end
