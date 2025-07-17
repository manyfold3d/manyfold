class Integrations::MyMiniFactory::CreatorDeserializer < Integrations::MyMiniFactory::BaseDeserializer
  attr_reader :username

  def deserialize
    return {} unless valid?
    r = fetch "users/#{CGI.escapeURIComponent(@username)}"
    self.class.parse(r.body)
  end

  def self.parse(data)
    {
      name: data["name"],
      slug: data["username"].parameterize,
      notes: ReverseMarkdown.convert(data["bio"]),
      links_attributes: [{url: data["profile_url"] || "https://www.myminifactory.com/users/#{ERB::Util.u(data["username"])}"}]
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
    match = /\A\/users\/(#{USERNAME_PATTERN})\Z/o.match(CGI.unescape(path))
    @username = match[1] if match.present?
    match.present?
  end
end
