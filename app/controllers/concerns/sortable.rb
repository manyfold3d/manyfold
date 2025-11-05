module Sortable
  extend ActiveSupport::Concern

  included do
    before_action :remember_ordering
  end

  def remember_ordering
    session["order"] ||= "name"
    session["order"] = params["order"] if params["order"]
  end

  def apply_sort_order(scope)
    case session["order"]
    when "recent"
      scope.order(created_at: :desc)
    when "updated"
      scope.order(updated_at: :desc)
    else
      scope.order(name_lower: :asc)
    end
  end
end
