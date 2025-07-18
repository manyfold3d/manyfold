class Integrations::Cults3d::BaseDeserializer < Integrations::BaseDeserializer
  PATH_COMPONENTS = {
    locale: "(en|de|pt|es|fr|ru|zh)",
    users: "(users|benutzer|usuarios|utilisateurs|polzovateli|yònghù)",
    username: /(?<username>[[:alnum:]\-_ ]+)/,
    models: "(3d-models|3d-modelle|modelos-3d|fichiers-3d|3d-modeli|sānwèi-mó-xíng)",
    collections: "(collections|kollectionen|colecoes|kollektsii|shōucáng-pǐn)",
    collection: /(?<collection>[[:alnum:]\-_ ]+)/,
    model: "(3d-model|modell-3d|modelo-3d|modèle-3d|3d-móxíng)",
    category: "([[:alnum:]]+)",
    model_slug: /(?<model_slug>[[:alnum:]\-_ ]+)/
  }

  private

  def api_configured?
    SiteSettings.cults3d_api_key.present? && SiteSettings.cults3d_api_username.present?
  end

  def canonicalize(uri)
    u = URI.parse(uri)
    return if u.host != "cults3d.com"
    return unless valid_path?(u.path)
    # Force https
    u.scheme = "https"
    # Remove query and fragment
    u.query = u.fragment = nil
    u.to_s
  rescue URI::InvalidURIError
  end
  class << self
    def client
      @@client ||= Graphlient::Client.new(
        "https://#{SiteSettings.cults3d_api_username}:#{SiteSettings.cults3d_api_key}@cults3d.com/graphql",
        schema_path: "#{File.dirname(__FILE__)}/cults3d.json"
      )
    end
  end
end
