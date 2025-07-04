class Integrations::MyMiniFactory::CollectionDeserializer < Integrations::MyMiniFactory::BaseDeserializer
  def valid_path?(path)
    /\A\/users\/[[:alnum:]-]+\/collection\/[[:alnum:]-]+\Z/.match?(path)
  end
end
