class UploadPolicy < ApplicationPolicy
  def index?
    create?
  end

  def create?
    all_of(
      user&.is_contributor?,
      none_of(
        Flipper.enabled?(:demo_mode)
      )
    )
  end
end
