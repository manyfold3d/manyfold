class GroupsController < ApplicationController
  before_action :get_creator
  before_action :get_group, except: [:index, :new, :create]
  before_action :find_members, only: [:create, :update] # rubocop:todo Rails/LexicallyScopedActionFilter

  def index
    authorize Group.new(creator: @creator) # stub group to check authorization
    page = params[:page] || 1
    groups = policy_scope(@creator.groups).page(page).per(100)
    respond_to do |format|
      format.html { render Views::Groups::Index.new(groups: groups, creator: @creator) }
      format.manyfold_api_v0 { render json: ManyfoldApi::V0::GroupListSerializer.new(@creator, groups).serialize }
    end
  end

  def show
    authorize @group
    respond_to do |format|
      format.manyfold_api_v0 { render json: ManyfoldApi::V0::GroupSerializer.new(@group).serialize }
    end
  end

  def new
    group = @creator.groups.new
    authorize group
    respond_to do |format|
      format.html { render Views::Groups::New.new(group: group, creator: @creator) }
    end
  end

  def edit
    respond_to do |format|
      format.html { render Views::Groups::Edit.new(group: @group, creator: @creator) }
    end
  end

  def create
    group = @creator.groups.create group_params
    authorize group
    respond_to do |format|
      format.html do
        if group.valid?
          redirect_to creator_groups_path(@creator), notice: t(".success")
        else
          render Views::Groups::New.new(group: group, creator: @creator), status: :unprocessable_content
        end
      end
    end
  end

  def update
    @group.update group_params
    respond_to do |format|
      format.html do
        if @group.valid?
          redirect_to creator_groups_path(@creator), notice: t(".success")
        else
          render Views::Groups::Edit.new(group: @group, creator: @creator), status: :unprocessable_content
        end
      end
    end
  end

  def destroy
    @group.destroy!
    respond_to do |format|
      format.html { redirect_to creator_groups_path(@creator) }
    end
  end

  private

  def get_creator
    @creator = Creator.find_param(params[:creator_id])
  end

  def get_group
    @group = @creator.groups.find(params[:id])
    authorize @group
  end

  def group_params
    if is_api_request?
      raise ActionController::BadRequest unless params[:json]
      # ManyfoldApi::V0::GroupDeserializer.new(object: params[:json], user: current_user, record: @creator).deserialize
    else
      Form::GroupDeserializer.new(params: params, user: current_user, record: @creator).deserialize
    end
  end

  def find_members
    params.values.each do |param|
      if param.is_a?(ActionController::Parameters) && param.has_key?("memberships_attributes")
        param["memberships_attributes"].transform_values! do |value|
          if value.has_key? "user_id"
            user = case value["user_id"]
            when /[[:digit:]]+/
              # This should find the same ID, but will check the policy scope
              policy_scope(User).find(value["user_id"].to_i)
            when ""
              raise ActiveRecord::RecordNotFound
            else
              policy_scope(User).find_by!(username: value["user_id"])
            end
            value["user_id"] = user&.id
          end
          value
        rescue ActiveRecord::RecordNotFound
          nil
        end
        param["memberships_attributes"].compact!
      end
    end
  end
end
