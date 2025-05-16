class Search::RansackQueryTransformer < Parslet::Transform
  rule(term: simple(:term)) { term.to_s }
  rule(query: sequence(:terms)) {
    {
      m: "or",
      name_cont_any: terms,
      tags_name_in: terms,
      creator_name_cont_any: terms,
      collection_name_cont_any: terms
    }
  }
end
