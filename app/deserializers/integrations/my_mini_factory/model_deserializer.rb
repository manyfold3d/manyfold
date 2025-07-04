class Integrations::MyMiniFactory::ModelDeserializer < Integrations::MyMiniFactory::BaseDeserializer
  def valid_path?(path)
    /\A\/object\/3d-print-[[:alnum:]-]+\Z/.match?(path)
  end
end
