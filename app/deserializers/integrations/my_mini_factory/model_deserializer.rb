class Integrations::MyMiniFactory::ModelDeserializer < Integrations::MyMiniFactory::BaseDeserializer
  attr_reader :object_id

  def valid_path?(path)
    match = /\A\/object\/3d-print-[[:alnum:]-]+-([[:digit:]]+)\Z/.match(path)
    @object_id = match[1] if match.present?
    match.present?
  end
end
