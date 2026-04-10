module Likeable
  extend ActiveSupport::Concern

  def like_count
    calculate_like_count
  end

  private

  def calculate_like_count
    list_items.includes(:list).where("list.special": :liked).count +
      Federails::Activity.includes(:actor).where(action: "Like", entity: [self] + comments.where(system: true), 'actor.local': false).count
  end

end
