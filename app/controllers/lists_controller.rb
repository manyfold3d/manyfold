class ListsController < ApplicationController
  before_action :get_list, except: [:index, :new, :create]

  def index
    @lists = policy_scope(List).all
    respond_to do |format|
      format.html { render Views::Lists::Index.new(lists: @lists) }
    end
  end

  def show
    respond_to do |format|
      format.html { render Views::Lists::Show.new(list: @list) }
    end
  end

  def new
    @list = List.new
    authorize @list
    respond_to do |format|
      format.html { render Views::Lists::New.new(list: @list) }
    end
  end

  def edit
    respond_to do |format|
      format.html { render Views::Lists::Edit.new(list: @list) }
    end
  end

  def create
    @list = List.new(list_params)
    authorize @list
    respond_to do |format|
      format.html do
        if @list.save
          redirect_to @list, notice: t(".success")
        else
          render Views::Lists::New.new(list: @list), status: :unprocessable_content
        end
      end
    end
  end

  def update
    respond_to do |format|
      format.html do
        if @list.update(list_params)
          redirect_back_or_to @list, notice: t(".success"), status: :see_other
        else
          render Views::Lists::Edit.new(list: @list), status: :unprocessable_content
        end
      end
    end
  end

  def destroy
    @list.destroy!
    respond_to do |format|
      format.html { redirect_back_or_to lists_path, notice: t(".success"), status: :see_other }
    end
  end

  private

  def get_list
    @list = policy_scope(List).find_param(params.expect(:id))
    authorize @list
  end

  def list_params
    params.require(:list).permit( # rubocop:todo Rails/StrongParametersExpect
      :name,
      list_items_attributes: [:id, :listable_type, :listable_id, :_destroy]
    )
  end
end
