class ModelsController < ApplicationController
  before_action :get_library
  before_action :get_model, except: [:bulk_edit, :bulk_update]

  def show
    @groups = helpers.group(@model.model_files)
  end

  def edit
    @creators = Creator.all
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
    @models = @library.models
    if (@tag = params[:tag])
      @models = @models.tagged_with(@tag)
    end
    if params[:collection]
      @collection = ActsAsTaggableOn::Tag.for_context(:collections).find(params[:collection])
      @models = @models.tagged_with(@collection, context: :collection) if @collection
    end
  end

  def bulk_update
    hash = bulk_update_params
    hash[:library_id] = hash.delete(:new_library_id) if hash[:new_library_id]

    add_tags = Set.new(hash.delete(:add_tags))
    remove_tags = Set.new(hash.delete(:remove_tags))
    collection_list = Set.new(hash.delete(:collection_list)).compact_blank

    params[:models].each_pair do |id, selected|
      if selected == "1"
        model = @library.models.find(id)
        if model.update(hash)
          existing_tags = Set.new(model.tag_list)
          model.tag_list = existing_tags + add_tags - remove_tags
          model.collection_list = collection_list unless collection_list.empty?
          model.save
        end
      end
    end
    redirect_to edit_library_models_path(@library, tag: params[:tag])
  end

  def destroy
    @model.destroy
    redirect_to library_path(@library)
  end

  private

  def bulk_update_params
    params.permit(
      :scale_factor,
      :creator_id,
      :new_library_id,
      :organize,
      add_tags: [],
      remove_tags: [],
      collection_list: []
    ).compact_blank
  end

  def model_params
    params.require(:model).permit(
      :preview_file_id,
      :creator_id,
      :library_id,
      :name,
      :scale_factor,
      :organize,
      collection_list: [],
      tag_list: [],
      links_attributes: [:id, :url, :_destroy]
    )
  end

  def get_library
    @library = Library.find(params[:library_id])
  end

  def get_model
    @model = @library.models.includes(:model_files, :creator).find(params[:id])
    @title = @model.name
  end
end
