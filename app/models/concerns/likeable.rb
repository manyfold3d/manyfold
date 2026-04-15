module Likeable
  extend ActiveSupport::Concern

  def update_like_count!
    count = list_items.includes(:list).where("list.special": :liked).count +
      Federails::Activity.includes(:actor).where(action: "Like", entity: [self] + comments.where(system: true), "actor.local": false).count # rubocop:disable Pundit/UsePolicyScope
    update_attribute(:like_count, count) # rubocop:disable Rails/SkipsModelValidations
  end
end
