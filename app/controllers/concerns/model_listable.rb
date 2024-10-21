module ModelListable
  extend ActiveSupport::Concern

  included do
    include TagListable
    include Filterable
  end

  private

  def prepare_model_list
    # Work out policies for showing buttons up front
    @can_destroy = policy(Model).destroy?
    @can_edit = policy(Model).edit?

    # Ordering
    @models = case session["order"]
    when "recent"
      @models.order(created_at: :desc)
    else
      @models.order(name_lower: :asc)
    end

    @tags, @unrelated_tag_count = generate_tag_list(@models, @filter_tags)
    @tags, @kv_tags = split_key_value_tags(@tags)

    if helpers.pagination_settings["models"]
      page = params[:page] || 1
      @models = @models.page(page).per(helpers.pagination_settings["per_page"])
    end

    # Load extra data
    @models = @models.includes [:library, :model_files, :preview_file, :creator, :collection]
  end
end
