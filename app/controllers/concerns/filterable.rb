module Filterable
  extend ActiveSupport::Concern
  included do
    before_action :get_filters, only: [:index, :show] # rubocop:todo Rails/LexicallyScopedActionFilter
  end

  def get_filters
    # Get list filters from URL
    @filter = Search::FilterService.new(params)
    @filters = @filter.to_params
  end

  def filtered_models(filters)
    @collection = @filter.collection
    @creator = @filter.creator
    @filter_tags = ActsAsTaggableOn::Tag.named_any(@filter.parameter(:tag)) if @filter.filtering_by?(:tag)
    @filter.models(policy_scope(Model))
  end

  def filtered_collections(filters)
    @filter.collections(policy_scope(Collection))
  end
end
