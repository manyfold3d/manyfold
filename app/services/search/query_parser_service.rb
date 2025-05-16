# Search query parsing is heavily based on
# http://recursion.org/query-parser. Thanks ❤️
class Search::QueryParserService < Parslet::Parser
  root(:query)
  rule(:operator) { match("[+-]").as(:operator) }
  rule(:clause) { (operator.maybe >> prefix_with_separator.maybe >> (term.as(:term) | quoted_term)) }
  rule(:query) { (clause >> space.maybe).repeat.as(:query) }
  rule(:quoted_term) { (quote >> (term >> space.maybe).repeat.as(:term) >> quote) }
  rule(:term) { match('[^\s"]').repeat(1) }
  rule(:prefix_with_separator) { (prefix >> separator) }
  rule(:separator) { match(":") }
  rule(:quote) { match('"') }
  rule(:prefix) { match("[a-z]").repeat(1).as(:prefix) }
  rule(:space) { match('\s').repeat(1) }
end
