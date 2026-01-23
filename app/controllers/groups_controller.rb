class GroupsController < ApplicationController
  before_action :get_creator
  before_action :get_group, except: [:index, :new, :create]
  before_action :find_members, only: [:create, :update] # rubocop:todo Rails/LexicallyScopedActionFilter
  after_action :send_notifications, only: [:create, :update]

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
    @group = @creator.groups.create group_params
    @new_memberships = @group.reload.memberships if @group.valid?
    authorize @group
    respond_to do |format|
      format.html do
        if @group.valid?
          redirect_to creator_groups_path(@creator), notice: t(".success")
        else
          render Views::Groups::New.new(group: @group, creator: @creator), status: :unprocessable_content
        end
      end
      format.manyfold_api_v0 do
        if @group.valid?
          render json: ManyfoldApi::V0::GroupSerializer.new(@group).serialize, status: :created, location: creator_group_path(@creator, @group)
        else
          render json: @group.errors.to_json, status: :unprocessable_content
        end
      end
    end
  end

  def update
    previous_membership_ids = @group.memberships.pluck(:id)
    @group.update group_params
    @new_memberships = @group.reload.memberships.where.not(id: previous_membership_ids) if @group.valid?
    respond_to do |format|
      format.html do
        if @group.valid?
          redirect_to creator_groups_path(@creator), notice: t(".success")
        else
          render Views::Groups::Edit.new(group: @group, creator: @creator), status: :unprocessable_content
        end
      end
      format.manyfold_api_v0 do
        if @group.valid?
          render json: ManyfoldApi::V0::GroupSerializer.new(@group).serialize
        else
          render json: @group.errors.to_json, status: :unprocessable_content
        end
      end
    end
  end

  def destroy
    @group.destroy!
    respond_to do |format|
      format.html { redirect_to creator_groups_path(@creator) }
      format.manyfold_api_v0 { head :no_content }
    end
  end

  private

  def send_notifications
    @new_memberships&.each do |it|
      NewGroupMemberNotifier.with(membership: it).deliver(it.user)
    end
  end

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
      ManyfoldApi::V0::GroupDeserializer.new(object: params[:json], user: current_user, record: @group).deserialize
    else
      Form::GroupDeserializer.new(params: params, user: current_user, record: @creator).deserialize
    end
  end

  def find_members
    params.values.each do |param|
      if param.is_a?(ActionController::Parameters) && param.has_key?("memberships_attributes")
        param["memberships_attributes"].transform_values! do |value|
          value["user_id"] = User.match!(identifier: value["user_id"], scope: policy_scope(User), invite: true)&.id if value.has_key? "user_id"
          value
        rescue ActiveRecord::RecordNotFound
        end
        param["memberships_attributes"].compact!
      end
    end
  end
end
