class Integrations::MyMiniFactory::CollectionDeserializer < Integrations::MyMiniFactory::BaseDeserializer
  attr_reader :collection_slug

  def valid_path?(path)
    match = /\A\/users\/[[:alnum:]-]+\/collection\/([[:alnum:]-]+)\Z/.match(path)
    @collection_slug = match[1] if match.present?
    match.present?
  end
end
