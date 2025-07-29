class Integrations::Cults3d::CreatorDeserializer < Integrations::Cults3d::BaseDeserializer
  attr_reader :username

  def deserialize
    return {} unless valid?
    result = self.class.client.query <<~GRAPHQL
      {
        user(nick: "#{@username}") {
          nick
          bio
          url
        }
      }
    GRAPHQL
    raise Faraday::ResourceNotFound.new("Not Found") unless result.data&.user
    self.class.parse(result.data&.user)
  end

  def self.parse(data)
    {
      name: data&.nick,
      slug: data&.nick&.parameterize,
      notes: data&.bio,
      links_attributes: [{url: data&.url}]
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
    match = /\A\/#{PATH_COMPONENTS[:locale]}\/#{PATH_COMPONENTS[:users]}\/#{PATH_COMPONENTS[:username]}(\/#{PATH_COMPONENTS[:models]})?\Z/o.match(CGI.unescape(path))
    @username = match[:username] if match.present?
    match.present?
  end
end
