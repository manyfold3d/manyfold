class Integrations::MyMiniFactory::CreatorDeserializer < Integrations::MyMiniFactory::BaseDeserializer
  attr_reader :username

  def valid_path?(path)
    match = /\A\/users\/([[:alnum:]]+)\Z/.match(path)
    @username = match[1] if match.present?
    match.present?
  end
end
