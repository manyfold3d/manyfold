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
    redirect_to [@library, @model]
  end

  def merge
    if (@parent = @model.parent)
      @model.merge_into_parent!
      redirect_to [@library, @parent]
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
  end

  def bulk_update
    params[:models].each_pair do |id, selected|
      if selected == "1"
        model = @library.models.find(id)
        model.update(bulk_update_params)
      end
    end
    redirect_to edit_library_models_path(@library, tag: params[:tag])
  end

  private

  def bulk_update_params
    params.permit(:creator_id)
  end

  def model_params
    params.require(:model).permit(
      :preview_file_id,
      :creator_id,
      :name,
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
