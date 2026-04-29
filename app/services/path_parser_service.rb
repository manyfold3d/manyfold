class PathParserService
  def initialize(template, path)
    @template = template
    @path = path
  end

  def call
    components = @path.match(path_parse_pattern)&.named_captures&.symbolize_keys
    return {} if components.nil?
    components.merge({
      tags: components[:tags]&.split(File::SEPARATOR)&.compact_blank,
      collections: components[:collection] ? [components.delete(:collection)] : components[:collections]&.split("/")&.compact_blank,
      model_id: nil # discard ID, never gonna use it in parsing
    }).compact_blank
  end

  private

  def path_parse_pattern
    Regexp.new("^/?.*?" +
      @template.gsub(/{.+?}/) { |token|
        case token
        when "{tags}"
          "(?<tags>[[:print:]]*)"
        when "{creator}"
          "(?<creator>[[:print:]&&[^#{File::SEPARATOR}]]*?)"
        when "{collection}"
          "(?<collection>[[:print:]&&[^#{File::SEPARATOR}]]*?)"
        when "{collections}"
          "(?<collections>[[:print:]]*)"
        when "{modelName}"
          "(?<model_name>[[:print:]&&[^#{File::SEPARATOR}]]*?)"
        when "{modelId}"
          "(?<model_id>#[[:digit:]]+)?"
        else
          "[[:print:]&&[^#{File::SEPARATOR}]]*"
        end
      } + "$")
  end
end
