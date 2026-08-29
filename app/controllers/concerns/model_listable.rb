module ModelListable
  extend ActiveSupport::Concern

  included do
    include TagListable
    include Filterable
    include Sortable
    include BrowseWindowable
  end

  private

  def prepare_model_list
    # Ordering
    @models = apply_sort_order(@models)

    stream = infinite_scroll_or_stream_request?
    if stream
      # Turbo-stream pages only append cards — skip tag-cloud work (INIT-009/SPEC-005).
      @tags = ActsAsTaggableOn::Tag.none
      @kv_tags = nil
      @unrelated_tag_count = nil
    else
      # Default images-only browse: use the global frequency cloud (threshold + limit)
      # instead of a semi-join over every matching model id (~9k). Restrict to the
      # filtered set only when the athlete applied a real facet (INIT-009/SPEC-005).
      models_for_tags = browse_tag_cloud_needs_model_scope? ? @models : nil
      @tags, @unrelated_tag_count = generate_tag_list(models_for_tags, @filter.tags)
      @tags, @kv_tags = split_key_value_tags(@tags)
      @unrelated_tag_count = nil unless @filter.any?
    end

    # Count before includes (avoids DISTINCT inflation / join cost); eager-load before window.
    total = @models.except(:order).count
    @models = @models.includes([:creator, :collection, :tags]).preload([:preview_file])
    @models = prepare_browse_window(@models, total: total)
  end

  # True when a non-default facet is active (creator/tag/q/…) so the tag cloud
  # should reflect the filtered set. Pure has_image (default browse) is false.
  def browse_tag_cloud_needs_model_scope?
    return false unless defined?(@filter) && @filter

    @filter.to_params.except(:has_image).present?
  end

  # Options for the models index filter form (lazy Turbo Frame or explicit call).
  def load_model_filter_sidebar_options
    return unless controller_name == "models"
    return unless %w[index filter_facets].include?(action_name)
    return if action_name == "index" && (
      turbo_frame_request? || request.format.turbo_stream? || request.headers["X-Infinite-Scroll"].present?
    )
    return unless request.format.html?

    visible_models = policy_scope(Model)
    @filter_libraries = policy_scope(Library).order(Arel.sql("LOWER(libraries.name) ASC"))
    @filter_creators = policy_scope(Creator)
      .where(id: visible_models.where.not(creator_id: nil).select(:creator_id))
      .order(Arel.sql("LOWER(creators.name) ASC"))
      .limit(1000)
    @filter_collections = policy_scope(Collection)
      .where(id: visible_models.where.not(collection_id: nil).select(:collection_id))
      .order(Arel.sql("LOWER(collections.name) ASC"))
      .limit(1000)
  end
end
