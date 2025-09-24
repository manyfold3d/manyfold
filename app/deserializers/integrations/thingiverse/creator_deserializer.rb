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
      slug: data["name"],
      notes: data["bio"],
      links_attributes: [{url: data["public_url"]}],
      avatar_remote_url: data["thumbnail"],
      banner_remote_url: data["cover_image"]
    }
  end

  def capabilities
    {
      class: Creator,
      name: true,
      slug: true,
      notes: true
    }
  end

  private

  def valid_path?(path)
    match = /\A\/(#{USERNAME_PATTERN})\Z/o.match(CGI.unescape(path))
    @username = match[1] if match.present?
    match.present?
  end
end
