class ListsController < ApplicationController
  before_action :get_list, except: [:index, :new, :create]
  before_action :check_list_item_permissions, only: [:create, :update]

  def index
    @lists = policy_scope(current_user.lists).all
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
    @list = List.new(list_params.merge(owner: current_user))
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
        if @list.update(list_params(list: @list))
          redirect_back_or_to @list, notice: (@list.special? ? nil : t(".success")), status: :see_other
        else
          render Views::Lists::Edit.new(list: @list), status: :unprocessable_content
        end
      end
    end
  end

  def destroy
    @list.destroy!
    respond_to do |format|
      format.html { redirect_to lists_path, notice: t(".success"), status: :see_other }
    end
  end

  private

  def get_list
    @list = policy_scope(List).find_param(params.expect(:id))
    authorize @list
  end

  def list_params(list: nil)
    if list&.special
      params.require(:list).permit( # rubocop:todo Rails/StrongParametersExpect
        list_items_attributes: [:id, :listable_type, :listable_id, :_destroy]
      )
    else
      params.require(:list).permit( # rubocop:todo Rails/StrongParametersExpect
        :name, # i18n-tasks-use t("activerecord.attributes.list.name")
        list_items_attributes: [:id, :listable_type, :listable_id, :_destroy] # i18n-tasks-use t("activerecord.attributes.list.list_items")
      )
    end
  end

  def check_list_item_permissions
    params.values.each do |param|
      if param.is_a?(ActionController::Parameters) && param.has_key?("list_items_attributes")
        param["list_items_attributes"].transform_values! do |value|
          if value["listable_id"] && value["listable_type"].in?(List::SUPPORTED_ITEM_TYPES)
            listable = policy_scope(value["listable_type"].constantize)&.find(value["listable_id"])
            value["listable_id"] = listable&.id
            value["listable_type"] = listable&.class&.name
          end
          value
        rescue ActiveRecord::RecordNotFound
          nil
        end
        param["list_items_attributes"].compact!
      end
    end
  end
end
