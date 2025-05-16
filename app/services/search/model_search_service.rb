class Search::ModelSearchService
  def initialize(scope)
    @scope = scope
  end

  def search(query)
    parse_tree = Search::QueryParserService.new.parse(query)
    @scope.ransack(
      Search::RansackQueryTransformer.new.apply(parse_tree)
    ).result(distinct: true)
  end
end
