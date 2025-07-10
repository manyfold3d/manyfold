class Integrations::Cults3d::CreatorDeserializer < Integrations::Cults3d::BaseDeserializer
  attr_reader :username

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
    Creator
  end

  def valid_path?(path)
    match = /\A\/#{PATH_COMPONENTS[:locale]}\/#{PATH_COMPONENTS[:users]}\/#{PATH_COMPONENTS[:username]}(\/#{PATH_COMPONENTS[:models]})?\Z/o.match(CGI.unescape(path))
    @username = match[:username] if match.present?
    match.present?
  end
end
