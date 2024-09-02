module CaberSubject
  extend ActiveSupport::Concern
  include Caber::Subject

  included do
    can_have_permissions_on Creator
    can_have_permissions_on Collection
    can_have_permissions_on Model
  end
end
