module Sortable
  extend ActiveSupport::Concern

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
