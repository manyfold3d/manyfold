# frozen_string_literal: true

# INIT-013/SPEC-003 — administrator-only performance dashboard / KPI JSON.
class PerformancePolicy < ApplicationPolicy
  def index?
    user&.is_administrator?
  end
end
