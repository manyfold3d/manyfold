class Integrations::Thingiverse::CreatorDeserializer < Integrations::Thingiverse::BaseDeserializer
  attr_reader :username

  def deserialize
    return {} unless valid?
    r = fetch "users/#{CGI.escapeURIComponent(@username)}"
    {
      name: r.body["name"],
      notes: r.body["bio"]
    }
  end

  private

  def target_class
    Creator
  end

  def valid_path?(path)
    match = /\A\/(#{USERNAME_PATTERN})\Z/o.match(CGI.unescape(path))
    @username = match[1] if match.present?
    match.present?
  end
end
