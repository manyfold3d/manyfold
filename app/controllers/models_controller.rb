require "fileutils"

class ModelsController < ApplicationController
  before_action :get_library, except: [:index, :bulk_edit, :bulk_update]
  before_action :get_model, except: [:bulk_edit, :bulk_update, :index]
  before_action :get_filters, only: [:bulk_edit, :bulk_update, :index]

  def index
    @models = Model.all.includes(:tags, :preview_file, :creator)

    if current_user.pagination_settings["models"]
      page = params[:page] || 1
      @models = @models.page(page).per(current_user.pagination_settings["per_page"])
    end

    # libraries may (probably) have wildly varying sets of tags (passed on for use in tag cloud)
    @tags = if @filters[:library]
      Model.includes(:tags).where(library: @filters[:library])
    else
      Model.includes(:tags)
    end
    @tags = @tags.map(&:tags).flatten.uniq.select { |x| x.taggings_count >= SiteSettings.model_tags_cloud_threshhold }
    @tags = case SiteSettings.model_tags_cloud_sorting
    when "alphabetical"
      @tags.sort_by(&:name)
    else
      @tags.sort_by(&:name).reverse.sort_by(&:taggings_count).reverse
    end

    process_filters

    # this is used for tag cloud for highlighting
    @commontags = ActsAsTaggableOn::Tag.joins(:taggings).where(taggings: {taggable: @models.except(:limit, :offset, :distinct)})
  end

  def show
    @groups = helpers.group(@model.model_files)
  end

  def edit
    @creators = Creator.all
    @collections = Collection.all
    @model.links.build if @model.links.empty? # populate empty link
  end

  def update
    @model.update(model_params)
    redirect_to [@model.library, @model]
  end

  def merge
    if (target = (@model.parents.find { |x| x.id == params[:target].to_i }))
      @model.merge_into! target
      redirect_to [@library, target]
    else
      render status: :bad_request
    end
  end

  def bulk_edit
    @creators = Creator.all
    @collections = Collection.all
    @models = Model.all
    process_filters
  end

  def bulk_update
    hash = bulk_update_params
    hash[:library_id] = hash.delete(:new_library_id) if hash[:new_library_id]

    add_tags = Set.new(hash.delete(:add_tags))
    remove_tags = Set.new(hash.delete(:remove_tags))

    params[:models].each_pair do |id, selected|
      if selected == "1"
        model = Model.find(id)
        if model.update(hash)
          existing_tags = Set.new(model.tag_list)
          model.tag_list = existing_tags + add_tags - remove_tags
          model.save
        end
      end
    end
    redirect_to edit_models_path(@filters)
  end

  def destroy
    @model.destroy

    # Delete directory corresponding to model
    pathname = File.join(@library.path, @model.path)
    FileUtils.remove_dir(pathname) if File.exist?(pathname)

    redirect_to library_path(@library)
  end

  private

  def bulk_update_params
    params.permit(
      :creator_id,
      :collection_id,
      :new_library_id,
      :organize,
      add_tags: [],
      remove_tags: []
    ).compact_blank
  end

  def model_params
    params.require(:model).permit(
      :preview_file_id,
      :creator_id,
      :library_id,
      :name,
      :caption,
      :notes,
      :collection,
      :q,
      :library,
      :creator,
      :tag,
      :organize,
      :missingtag,
      tag_list: [],
      links_attributes: [:id, :url, :_destroy]
    )
  end

  def get_library
    @library = Model.find(params[:id]).library
  end

  def get_model
    @model = Model.includes(:model_files, :creator).find(params[:id])
    @title = @model.name
  end

  def get_filters
    # Get list filters from URL
    @filters = params.permit(:library, :collection, :q, :creator, :link, :missingtag, tag: [])
  end

  def process_filters
    # Ordering
    @models = case session["order"]
    when "recent"
      @models.order(created_at: :desc)
    else
      @models.order(name: :asc)
    end

    # filter by library?
    @models = @models.where(library: params[:library]) if @filters[:library]
    @addtags = @models.includes(:tags).map(&:tags).flatten.uniq.sort_by(&:name)

    # Missing tags (only valid if one library)
    if @filters[:missingtag] && @filters[:library]
      tag_regex_build = []
      regexes = ((@filters[:missingtag] != "") ? [@filters[:missingtag]] : @models[0].library.tag_regex)
      regexes.each do |reg|
        qreg = ActiveRecord::Base.connection.quote(reg)
        if Rails.env.development?
          tag_regex_build.push "(select count(*) from tags join taggings on tags.id=taggings.tag_id where tags.name REGEXP #{qreg} and taggings.taggable_id=models.id and taggings.taggable_type='Model')<1"
        else
          tag_regex_build.push "(select count(*) from tags join taggings on tags.id=taggings.tag_id where tags.name ~ #{qreg} and taggings.taggable_id=models.id and taggings.taggable_type='Model')<1"
        end
      end
      qreg = ActiveRecord::Base.connection.quote(@filters[:missingtag])
      if Rails.env.development?
        tag_regex_build.push "(select count(*) from tags join taggings on tags.id=taggings.tag_id where tags.name REGEXP #{qreg} and taggings.taggable_id=models.id and taggings.taggable_type='Model')<1"
      else
        tag_regex_build.push "(select count(*) from tags join taggings on tags.id=taggings.tag_id where tags.name ~ #{qreg} and taggings.taggable_id=models.id and taggings.taggable_type='Model')<1"
      end
      @models = @models.where("(" + tag_regex_build.join(" OR ") + ")")

    else

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
        @models = @models.where(collection: @collection)
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
      if @filters[:q]
        field = Model.arel_table[:name]
        creatorsearch = Creator.where("name LIKE ?", "%#{@filters[:q]}%")
        @models = @models.where("tags.name LIKE ?", "%#{@filters[:q]}%").or(@models.where(field.matches("%#{@filters[:q]}%"))).or(@models.where(creator_id: creatorsearch))
          .joins("LEFT JOIN taggings ON taggings.taggable_id=models.id AND taggings.taggable_type = 'Model' LEFT JOIN tags ON tags.id = taggings.tag_id").distinct
      end

    end
  end
end
