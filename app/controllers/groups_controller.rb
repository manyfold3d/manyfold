class GroupsController < ApplicationController
  before_action :get_creator
  before_action :get_group, except: [:index, :new, :create]

  def index
    groups = policy_scope(@creator.groups)
    authorize @creator.groups.new # stub group to check authorization
    respond_to do |format|
      format.html { render Views::Groups::Index.new(groups: groups, creator: @creator) }
    end
  end

  def show
    respond_to do |format|
      format.html { render Views::Groups::Show.new(group: @group, creator: @creator) }
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
    group = @creator.groups.create
    authorize group
    respond_to do |format|
      format.html { redirect_to creator_group_path(@creator, group) }
    end
  end

  def update
    respond_to do |format|
      format.html { redirect_to creator_group_path(@creator, @group) }
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
end
