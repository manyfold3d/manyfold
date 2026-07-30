class ActivityPub::LikeActivityHandler
  def self.handle_like_activity(activity_hash_or_id)
    activity = Fediverse::Request.dereference(activity_hash_or_id)
    actor = Fedipub::Actor.find_or_create_by_object activity["actor"]
    object = Fediverse::Request.dereference(activity["object"])
    entity = begin
      Fedipub::Actor.find_by_federation_url(object["id"])&.entity # rubocop:disable Rails/DynamicFindBy
    rescue ActiveRecord::RecordNotFound
      Fedipub::Utils::Object.find_or_create!(object)
    end
    raise ActiveRecord::RecordNotFound unless entity
    Fedipub::Activity.create! actor: actor, action: "Like", entity: entity
    entity.is_a?(Comment) ? entity.commentable.update_like_count! : entity.update_like_count!
  end
end
