class RansackQueryTransformer < Parslet::Transform
  rule(term: simple(:term)) { term.to_s }
  rule(query: sequence(:terms)) {
    search = terms.join(" ")
    {
      m: "or",
      name_cont: search,
      tags_name_in: search,
      creator_name_cont: search,
      collection_name_cont: search
    }
  }
end
