module TagListable
  def generate_tag_list(models = nil, filter_tags = nil)
    # All tags bigger than threshold
    tags = all_tags = ActsAsTaggableOn::Tag.where(taggings_count: helpers.tag_cloud_settings["threshold"]..)
    # Ignore any tags that have been applied as filters
    tags = all_tags = tags.where.not(id: filter_tags) if filter_tags
    # Generate a list of tags shared by the list of models
    tags = tags.includes(:taggings).where("taggings.taggable": models.pluck(:id)) if models
    # Apply tag sorting
    tags = case helpers.tag_cloud_settings["sorting"]
    when "alphabetical"
      tags.order(name: :asc)
    else
      tags.order(taggings_count: :desc, name: :asc)
    end
    # Work out how many tags were unrelated and will be hidden
    unrelated_tag_count = models ? (all_tags.count - tags.count) : 0
    # Only get what we need for rendering
    tags = tags.select(:name, :taggings_count)
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
end
