class UploadPolicy < ApplicationPolicy
  def index?
    !Flipper.enabled? :demo_mode
  end

  def create?
    !Flipper.enabled? :demo_mode
  end
end
