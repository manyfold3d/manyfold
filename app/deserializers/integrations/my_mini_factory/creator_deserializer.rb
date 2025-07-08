class Integrations::MyMiniFactory::CreatorDeserializer < Integrations::MyMiniFactory::BaseDeserializer
  attr_reader :username

  def deserialize
    return {} unless valid?
    r = fetch "https://www.myminifactory.com/api/v2/users/#{CGI.escapeURIComponent(@username)}"
    {
      name: r.body["name"],
      notes: ReverseMarkdown.convert(r.body["bio"])
    }
  end

  private

  def target_class
    Creator
  end

  def valid_path?(path)
    match = /\A\/users\/(#{USERNAME_PATTERN})\Z/o.match(CGI.unescape(path))
    @username = match[1] if match.present?
    match.present?
  end
end
