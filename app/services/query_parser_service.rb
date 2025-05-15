class QueryParserService < Parslet::Parser
  root(:query)
  rule(:query) { (term >> space.maybe).repeat.as(:query) }
  rule(:term) { match('[^\s]').repeat(1).as(:term) }
  rule(:space) { match('\s').repeat(1) }
end
