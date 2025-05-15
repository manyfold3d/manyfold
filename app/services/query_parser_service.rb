# Search query parsing is heavily based on
# http://recursion.org/query-parser. Thanks ❤️
class QueryParserService < Parslet::Parser
  root(:query)
  rule(:operator) { match("[+-]").as(:operator) }
  rule(:clause) { (operator.maybe >> term) }
  rule(:query) { (clause >> space.maybe).repeat.as(:query) }
  rule(:term) { match('[^\s]').repeat(1).as(:term) }
  rule(:space) { match('\s').repeat(1) }
end
