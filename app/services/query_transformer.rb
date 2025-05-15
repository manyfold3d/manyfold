class QueryTransformer < Parslet::Transform
  rule(term: simple(:term)) { term.to_s }
  rule(query: sequence(:terms)) { SearchQuery.new(terms) }
end
