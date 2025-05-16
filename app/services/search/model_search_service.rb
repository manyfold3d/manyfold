class Search::ModelSearchService
  def initialize(scope)
    @scope = scope
  end

  def search(query)
    parse_tree = Search::QueryParserService.new.parse(query)
    q = Search::ScopedSearchQueryTransformer.new.apply(parse_tree)
    @scope.search_for(q).distinct
  end
end
