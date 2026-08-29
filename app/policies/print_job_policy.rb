# frozen_string_literal: true

# Authorization for PrintJob mutate actions (queue / start / plate-cleared).
# Aligns with PrintHostPolicy printer control (administrator, non-demo).
class PrintJobPolicy < ApplicationPolicy
  def index?
    user&.is_administrator?
  end

  def show?
    index?
  end

  def create?
    control?
  end

  def update?
    control?
  end

  def destroy?
    control?
  end

  def start?
    control?
  end

  def pause?
    control?
  end

  def resume?
    control?
  end

  def cancel?
    control?
  end

  def confirm_plate_cleared?
    control?
  end

  def control?
    all_of(
      user&.is_administrator?,
      none_of(SiteSettings.demo_mode_enabled?)
    )
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      user&.is_administrator? ? scope.all : scope.none
    end
  end
end
