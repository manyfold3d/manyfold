class QueryTransformer < Parslet::Transform
  rule(term: simple(:term)) { term.to_s }
  rule(query: sequence(:terms)) { RansackTransformer.new(terms) }
end
