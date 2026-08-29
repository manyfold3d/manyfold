module TagListable
  # Cap tag-cloud rows on browse HTML — chrome uses 14 chips; sidebar still needs a
  # bounded cloud so we never materialize every tag for a 40k-model library (INIT-009/SPEC-005).
  BROWSE_TAG_CLOUD_LIMIT = 100

  def generate_tag_list(models = nil, filter_tags = nil, limit: BROWSE_TAG_CLOUD_LIMIT)
    # All tags bigger than threshold
    tags = all_tags = policy_scope(ActsAsTaggableOn::Tag).where(taggings_count: helpers.tag_cloud_settings["threshold"]..)
    # Ignore any tags that have been applied as filters
    tags = all_tags = tags.where.not(id: filter_tags) if filter_tags
    # Restrict to tags used by the filtered models — via SQL subquery, never models.map(&:id)
    if models
      tags = tags.joins(:taggings).where(
        taggings: {taggable_type: "Model", taggable_id: taggable_model_ids_scope(models)}
      ).group("tags.id", "tags.name", "tags.taggings_count")
    end
    # Apply tag sorting
    tags = case helpers.tag_cloud_settings["sorting"]
    when "alphabetical"
      tags.order(name: :asc)
    else
      tags.order(taggings_count: :desc, name: :asc)
    end
    # Skip all_tags.count - tags.count (two full COUNTs over the library). Callers
    # already nil @unrelated_tag_count unless a filter is active.
    unrelated_tag_count = 0
    # Only get what we need for rendering
    tags = tags.select("tags.name", "tags.taggings_count")
    tags = tags.limit(limit) if limit
    # Done!
    [tags, unrelated_tag_count]
  end

  def split_key_value_tags(tags)
    # Split into plain tags and key-value tags
    if helpers.tag_cloud_settings["keypair"]
      plain_tags = tags.where.not("name LIKE '%:%'")
      kv_tags = tags.where("name LIKE '%:%'")
    else
      plain_tags = tags
      kv_tags = nil
    end
    [plain_tags, kv_tags]
  end

  private

  # Keep this as a Relation when possible so Postgres never materializes 40k+ IDs in Ruby.
  # Do NOT except(:includes) — policy_scope may JOIN caber_relations into WHERE.
  def taggable_model_ids_scope(models)
    case models
    when ActiveRecord::Relation
      table = models.klass.arel_table
      models.except(:order, :select, :limit, :offset, :group, :having, :preload, :eager_load)
        .reselect(table[:id])
        .distinct
    when Array
      models.map { |m| m.respond_to?(:id) ? m.id : m }
    else
      Array(models).map { |m| m.respond_to?(:id) ? m.id : m }
    end
  end
end
