class QueryParserService < Parslet::Parser
  root(:query)
  rule(:query) { term.repeat.as(:query) }
  rule(:term) { match("[a-zA-Z0-9\s]").repeat(1).as(:term) }
end
