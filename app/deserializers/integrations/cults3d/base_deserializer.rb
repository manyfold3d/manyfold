class Integrations::Cults3d::BaseDeserializer < Integrations::BaseDeserializer
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
end
