class Integrations::Cults3d::CollectionDeserializer < Integrations::Cults3d::BaseDeserializer
  attr_reader :collection_slug

  def deserialize
    return {} unless valid?
    # TODO: fetch data
    {
      # TODO: name
      # TODO: notes
    }
  end

  private

  def target_class
    Collection
  end

  def valid_path?(path)
    match = /\A\/#{PATH_COMPONENTS[:locale]}\/#{PATH_COMPONENTS[:collections]}\/#{PATH_COMPONENTS[:collection]}\Z/o.match(CGI.unescape(path))
    @collection_slug = match[:collection] if match.present?
    match.present?
  end
end
