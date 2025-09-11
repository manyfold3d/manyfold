module Filterable
  extend ActiveSupport::Concern

  included do
    before_action :get_filters, only: [:index, :show] # rubocop:todo Rails/LexicallyScopedActionFilter
  end

  def get_filters
    @filter = Search::FilterService.new(params)
  end
end
