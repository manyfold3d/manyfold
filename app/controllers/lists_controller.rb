class ListsController < ApplicationController
  before_action :get_list, except: [:index, :new, :create]

  def index
    @lists = policy_scope(List).all
  end

  def show
  end

  def new
    @list = List.new
    authorize @list
  end

  def edit
  end

  def create
    @list = List.new(list_params)
    authorize @list
    respond_to do |format|
      if @list.save
        format.html { redirect_to @list, notice: t(".success") }
      else
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @list.update(list_params)
        format.html { redirect_to @list, notice: t(".success"), status: :see_other }
      else
        format.html { render :edit, status: :unprocessable_content }
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

  def list_params
    params.expect(list: [
      :name
    ])
  end
end
