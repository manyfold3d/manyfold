class RansackTransformer
  def initialize(scope, query)
    @scope = scope
    @query = query
  end

  def ransack_options
    term = @query.dig(:query, 0, :term)
    {
      m: "or",
      name_cont: term,
      tags_name_in: term,
      creator_name_cont: term,
      collection_name_cont: term
    }
  end

  def perform
    @scope.ransack(ransack_options).result(distinct: true)
  end
end
