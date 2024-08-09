module Timeline
  def self.local(actions = ["Create", "Update"], entity_types = ["Federails::Actor"], limit = 20)
    Federails::Activity.where(action: actions, entity_type: entity_types).order(created_at: :desc).limit(limit)
  end
end
