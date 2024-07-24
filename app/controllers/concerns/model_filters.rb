module ModelFilters
  extend ActiveSupport::Concern
  included do
    before_action :get_filters, only: [:bulk_edit, :bulk_update, :index, :show] # rubocop:todo Rails/LexicallyScopedActionFilter
  end

  def get_filters
    # Get list filters from URL
    @filters = params.permit(:library, :collection, :q, :creator, :link, :missingtag, :order, tag: [])
  end

  def process_filters_init
    @models = policy_scope(Model).includes(:tags, :preview_file, :creator, :collection)
  end

  def generate_tag_list(models = nil, filter_tags = nil)
    # All tags bigger than threshold
    tags = all_tags = ActsAsTaggableOn::Tag.where(taggings_count: current_user.tag_cloud_settings["threshold"]..)
    # Ignore any tags that have been applied as filters
    tags = all_tags = tags.where.not(id: filter_tags) if filter_tags
    # Generate a list of tags shared by the list of models
    tags = tags.includes(:taggings).where("taggings.taggable": models) if models
    # Apply tag sorting
    tags = case current_user.tag_cloud_settings["sorting"]
    when "alphabetical"
      tags.order(name: :asc)
    else
      tags.order(taggings_count: :desc, name: :asc)
    end
    # Work out how many tags were unrelated and will be hidden
    unrelated_tag_count = models ? (all_tags.count - tags.count) : 0
    # Done!
    [tags, unrelated_tag_count]
  end

  def process_filters
    # filter by library?
    @models = @models.where(library: params[:library]) if @filters[:library]

    # Missing tags (If specific tag is not specified, require library to be set)
    if @filters[:missingtag].presence || (@filters[:missingtag] && @filters[:library])
      tag_regex_build = []
      regexes = ((@filters[:missingtag] != "") ? [@filters[:missingtag]] : @models[0].library.tag_regex)
      # Regexp match syntax - postgres is different from MySQL and SQLite
      regact = ApplicationRecord.connection.is_a?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) ? "~" : "REGEXP"
      regexes.each do |reg|
        qreg = ActiveRecord::Base.connection.quote(reg)
        tag_regex_build.push "(select count(*) from tags join taggings on tags.id=taggings.tag_id where tags.name #{regact} #{qreg} and taggings.taggable_id=models.id and taggings.taggable_type='Model')<1"
      end
      qreg = ActiveRecord::Base.connection.quote(@filters[:missingtag])
      tag_regex_build.push "(select count(*) from tags join taggings on tags.id=taggings.tag_id where tags.name #{regact} #{qreg} and taggings.taggable_id=models.id and taggings.taggable_type='Model')<1"
      @models = @models.where("(" + tag_regex_build.join(" OR ") + ")")
    end

    # Filter by tag?
    case @filters[:tag]
    when nil
      nil # No tags, move along
    when [""]
      @models = @models.where("(select count(*) from taggings where taggings.taggable_id=models.id and taggings.context='tags')<1")
    else
      @filter_tags = ActsAsTaggableOn::Tag.named_any(@filters[:tag])
      @models = @models.tagged_with(@filters[:tag])
    end

    # Filter by collection?
    case @filters[:collection]
    when nil
      nil # No collection, move along
    when ""
      @models = @models.where(collection_id: nil)
    else
      @collection = Collection.find(@filters[:collection])
      @models = @models.where(collection: Collection.tree_down(@filters[:collection]))
    end

    # Filter by creator
    case @filters[:creator]
    when nil
      nil # No creator specified, nothing to do
    when ""
      @models = @models.where(creator_id: nil)
    else
      @creator = Creator.find(@filters[:creator])
      @models = @models.where(creator: @creator)
    end

    # Filter by url link (only coded "missing" url links UI for now)
    case @filters[:link]
    when nil
      nil # no filter
    when ""
      @models = @models.where("(select count(*) from links where linkable_id=models.id and linkable_type='Model')<1")
    else
      @models = @models.where("(select count(*) from links where linkable_id=models.id and linkable_type='Model' and url like ?)>0", "%#{@filters[:link]}%")
    end

    # keyword search filter
    # todo: haven't added collection here yet
    if @filters[:q]
      field = Model.arel_table[:name]
      creatorsearch = Creator.where("name LIKE ?", "%#{@filters[:q]}%")
      @models = @models.where("tags.name LIKE ?", "%#{@filters[:q]}%").or(@models.where(field.matches("%#{@filters[:q]}%"))).or(@models.where(creator_id: creatorsearch))
        .joins("LEFT JOIN taggings ON taggings.taggable_id=models.id AND taggings.taggable_type = 'Model' LEFT JOIN tags ON tags.id = taggings.tag_id").distinct
    end
  end
end
