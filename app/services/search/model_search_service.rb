class Search::ModelSearchService
  def initialize(scope)
    @scope = scope
  end

  def search(query)
    @scope.search_for(query).distinct
  end
end
