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
    collections = policy_scope(Collection).includes(:creator)
    collections = filter_collection_by_collection(collections, filters[:collection])
    collections = filter_collection_by_creator(collections, filters[:creator])
    collections = Search::ModelSearchService.new(collections).search(@filter.parameter(:q)) if @filter.filtering_by?(:q)
    collections
  end

  private

  def filter_collection_by_collection(collections, collection)
    case collection
    when nil
      collections
    when ""
      collections.where(collection: nil)
    else
      collections.where(collection: Collection.find_param(collection))
    end
  end

  def filter_collection_by_creator(collections, creator)
    case creator
    when nil
      collections
    when ""
      collections.where(creator_id: nil)
    else
      collections.where(creator: Creator.find_param(creator))
    end
  end
end
