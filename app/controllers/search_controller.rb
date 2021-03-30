class SearchController < ApplicationController
  before_action :check_for_first_use

  def index
    @query = params[:q]
    if @query
      field = Model.arel_table[:name]
      @results = Model.where(field.matches("%#{@query}%"))
      @results += Model.tagged_with(@query)
    end
  end

  private

  def check_for_first_use
    redirect_to new_library_path if Library.count === 0
  end
end
