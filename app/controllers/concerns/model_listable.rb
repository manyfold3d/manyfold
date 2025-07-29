module ModelListable
  extend ActiveSupport::Concern

  included do
    include TagListable
    include Filterable
  end

  private

  def prepare_model_list
    # Ordering
    @models = case session["order"]
    when "recent"
      @models.order(created_at: :desc)
    else
      @models.order(name_lower: :asc)
    end

    @tags, @unrelated_tag_count = generate_tag_list(@models, @filter.tags)
    @tags, @kv_tags = split_key_value_tags(@tags)
    @unrelated_tag_count = nil unless @filter.any?

    if helpers.pagination_settings["models"]
      page = params[:page] || 1
      @models = @models.page(page).per(helpers.pagination_settings["per_page"])
    end

    # Load extra data
    @models = @models.includes [:creator, :collection]
    @models = @models.preload [:model_files, :preview_file] # Use preload query to avoid joining JSON fields
  end
end
