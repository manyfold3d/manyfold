module DoorkeeperApplicationsHelper
  def token_expiry_string(token)
    return t(".revoked") if token.revoked?
    return t(".never") if token.expires_in.nil?
    expires_at = token.created_at + token.expires_in
    return t(".expired") if expires_at < Time.now.utc
    distance_of_time_in_words(Time.now.utc, expires_at)
  end

  def token_fingerprint(token)
    Digest::SHA256.hexdigest(token.token).first(8)
  end
end
