class QueryParserService
  def parse(query)
    {
      query: [
        {term: query}
      ]
    }
  end
end
