module CaberObject
  extend ActiveSupport::Concern
  include Caber::Object

  included do
    can_grant_permissions_to User
    can_grant_permissions_to Role

    attribute :owner, default: -> { SiteSettings.default_user }
    attribute :permission_preset, default: -> { SiteSettings.default_viewer_role }
    accepts_nested_attributes_for :caber_relations, reject_if: :all_blank, allow_destroy: true

    after_create_commit :set_permissions_from_preset
    after_create_commit :set_owner

    before_update -> { @was_private = !public? }

    def self.caber_owner(subject)
      {caber_relations_attributes: [{permission: "own", subject: subject}]}
    end
  end

  def public?
    return false unless caber_ready?
    Pundit::PolicyFinder.new(self.class).policy.new(nil, self).show?
  end

  def private?
    caber_relations.where(subject_type: "Role").or(caber_relations.where(subject: nil)).none?
  end

  def just_became_public?
    public? && @was_private
  end

  def set_permissions_from_preset
    case permission_preset.to_sym
    when :member
      grant_permission_to("view", Role.find_or_create_by(name: "member"))
    when :public
      grant_permission_to("view", nil)
    end
  end

  def set_owner
    # Set default owner if an owner isn't already set
    if permitted_users.with_permission("own").empty?
      grant_permission_to("own", owner) if owner
    end
  end

  def will_be_public?
    return false unless caber_ready?
    caber_relations.find { |it| it.subject.nil? }
  end

  private

  def caber_ready?
    ActiveRecord::Base.connection.data_source_exists? "caber_relations"
  end
end
