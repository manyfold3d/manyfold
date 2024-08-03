module TagListable
  def generate_tag_list(models = nil, filter_tags = nil)
    # All tags bigger than threshold
    tags = all_tags = ActsAsTaggableOn::Tag.where(taggings_count: current_user.tag_cloud_settings["threshold"]..)
    # Ignore any tags that have been applied as filters
    tags = all_tags = tags.where.not(id: filter_tags) if filter_tags
    # Generate a list of tags shared by the list of models
    tags = tags.includes(:taggings).where("taggings.taggable": models.map(&:id)) if models
    # Apply tag sorting
    tags = case current_user.tag_cloud_settings["sorting"]
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

end
