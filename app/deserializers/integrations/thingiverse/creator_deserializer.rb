class Integrations::Thingiverse::CreatorDeserializer < Integrations::Thingiverse::BaseDeserializer
  attr_reader :username

  def deserialize
    return {} unless valid?
    r = fetch "users/#{CGI.escapeURIComponent(@username)}"
    self.class.parse(r.body)
  end

  def self.parse(data)
    {
      name: data["name"],
      notes: data["bio"],
      links_attributes: [{url: data["public_url"]}]
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
