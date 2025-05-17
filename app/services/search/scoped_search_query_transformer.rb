class Search::ScopedSearchQueryTransformer < Parslet::Transform
  rule(term: simple(:term)) { term.to_s }
  rule(query: sequence(:terms)) { terms.map { |it| "\"#{it}\"" }.join(" or ") }
end
