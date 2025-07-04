class Integrations::MyMiniFactory::CreatorDeserializer < Integrations::MyMiniFactory::BaseDeserializer
  def valid_path?(path)
    /\A\/users\/[[:alnum:]]+\Z/.match?(path)
  end
end
