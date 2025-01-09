module Timeline
  ACCESS_PERMISSIONS = ["view", "edit", "own"]

  def self.local(actions = ["Create", "Update"], entity_types = ["Federails::Actor"], limit = 20, for_user: nil)
    Federails::Activity.where(action: actions, entity_type: entity_types).order(created_at: :desc).limit(limit).select do |activity|
      if activity.entity_type == "Federails::Actor"
        entity = activity.entity&.entity

        next false unless entity && !entity.is_a?(User)
        next entity.grants_permission_to?(ACCESS_PERMISSIONS, for_user) || entity.grants_permission_to?(ACCESS_PERMISSIONS, for_user&.roles)
      elsif activity.entity_type.demodulize.parameterize == "following"
        next true
      end

      false
    end
  end
end
