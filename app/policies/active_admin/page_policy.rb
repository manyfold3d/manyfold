# frozen_string_literal: true

class ActiveAdmin::PagePolicy < ApplicationPolicy
  def show?
    user&.is_administrator?
  end
end
