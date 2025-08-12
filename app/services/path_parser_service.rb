class PathParserService
  def initialize(template, path)
    @template = template
    @path = path
  end

  def call
    components = @path.match(path_parse_pattern)&.named_captures&.symbolize_keys
    return {} if components.nil?
    components.merge({
      tags: components[:tags]&.split("/")&.compact_blank,
      model_id: nil # discard ID, never gonna use it in parsing
    }).compact
  end

  private

  def path_parse_pattern
    Regexp.new("^/?.*?" +
      @template.gsub(/{.+?}/) { |token|
        case token
        when "{tags}"
          "(?<tags>[[:print:]]*)"
        when "{creator}"
          "(?<creator>[[:print:]&&[^/]]*?)"
        when "{collection}"
          "(?<collection>[[:print:]&&[^/]]*?)"
        when "{modelName}"
          "(?<model_name>[[:print:]&&[^/]]*?)"
        when "{modelId}"
          "" # Always detected by default, moved below, kept for compatibility
        else
          "[[:print:]&&[^/]]*"
        end
      } + "(?<model_id>#[[:digit:]]+)?" + "$")
  end
end
