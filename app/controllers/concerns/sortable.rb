module Sortable
  extend ActiveSupport::Concern

  included do
    before_action :remember_ordering
  end

  def current_ordering
    if current_user
      current_user.sort_order.to_s
    else
      session["order"].to_s
    end
  end

  def remember_ordering
    if current_user
      current_user.update!(sort_order: params["order"]) if params["order"].presence
    else
      session["order"] ||= "name"
      session["order"] = params["order"] if params["order"].presence
    end
  end

  def apply_sort_order(scope)
    case current_ordering
    when "recent"
      scope.order(created_at: :desc)
    when "updated"
      scope.order(updated_at: :desc)
    when "name"
      scope.order(name_lower: :asc)
    else
      scope
    end
  end
end
