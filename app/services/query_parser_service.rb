# Search query parsing is heavily based on
# http://recursion.org/query-parser. Thanks ❤️
class QueryParserService < Parslet::Parser
  root(:query)
  rule(:operator) { match("[+-]").as(:operator) }
  rule(:clause) { (operator.maybe >> prefix_with_separator.maybe >> term) }
  rule(:query) { (clause >> space.maybe).repeat.as(:query) }
  rule(:term) { match('[^\s]').repeat(1).as(:term) }
  rule(:prefix_with_separator) { (prefix >> separator) }
  rule(:separator) { match("[:]") }
  rule(:prefix) { match("[a-z]").repeat(1).as(:prefix) }
  rule(:space) { match('\s').repeat(1) }
end
