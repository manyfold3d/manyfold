class Integrations::Cults3d::ModelDeserializer < Integrations::Cults3d::BaseDeserializer
  attr_reader :object_slug

  def deserialize
    return {} unless valid?
    # TODO: fetch data
    {
      # TODO: name
      # TODO: notes
      # TODO: tag_list
      # TODO: sensitive
      # TODO: file_urls
      # TODO: preview_filename
    }
  end

  private

  def target_class
    Model
  end

  def valid_path?(path)
    match = /\A\/#{PATH_COMPONENTS[:locale]}\/#{PATH_COMPONENTS[:model]}\/#{PATH_COMPONENTS[:category]}\/#{PATH_COMPONENTS[:model_slug]}\Z/.match(path)
    @object_slug = match[:model_slug] if match.present?
    match.present?
  end
end
