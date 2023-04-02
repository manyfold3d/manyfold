module ModelFilters
  extend ActiveSupport::Concern
  included do
    before_action :get_filters, only: [:bulk_edit, :bulk_update, :index, :show]
  end

  def get_filters
    # Get list filters from URL
    @filters = params.permit(:library, :collection, :q, :creator, :link, :missingtag, :order, tag: [])
  end

  def process_filters_init
    @models = Model.all.includes(:tags, :preview_file, :creator, :collection)
  end

  def process_filters_tags_fetchall
    # libraries may (probably) have wildly varying sets of tags (passed on for use in tag cloud)
    # grab these before applying filters to get "all" applicable tags (if library filter is set trim to library)
    @tags = if @filters[:library]
      Model.includes(:tags).where(library: @filters[:library])
    else
      Model.includes(:tags)
    end
    @tags = @tags.map(&:tags).flatten.uniq.select { |x| x.taggings_count >= current_user.tag_cloud_settings["threshold"] }
    @tags = case current_user.tag_cloud_settings["sorting"]
    when "alphabetical"
      @tags.sort_by(&:name)
    else
      @tags.sort_by(&:name).reverse.sort_by(&:taggings_count).reverse
    end
  end

  def process_filters_tags_highlight
    # this is used for tag cloud for highlighting.  fetch after processing
    @commontags = ActsAsTaggableOn::Tag.joins(:taggings).where(taggings: {taggable: @models.except(:limit, :offset, :distinct)})
  end

  def process_filters
    # filter by library?
    @models = @models.where(library: params[:library]) if @filters[:library]
    @addtags = @models.includes(:tags).map(&:tags).flatten.uniq.sort_by(&:name)

    # Missing tags (If specific tag is not specified, require library to be set)
    if @filters[:missingtag].presence || (@filters[:missingtag] && @filters[:library])
      tag_regex_build = []
      regexes = ((@filters[:missingtag] != "") ? [@filters[:missingtag]] : @models[0].library.tag_regex)
      # technically this is sqlite vs postgres
      regact = Rails.env.development? ? "REGEXP" : "~"
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
      @tag = ActsAsTaggableOn::Tag.named_any(@filters[:tag])
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
