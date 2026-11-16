module UrlSafety
  def self.if_public(url)
    public?(url) ? url : nil
  end

  def self.public?(url)
    PrivateAddressCheck.resolves_to_private_address?(URI.parse(url).host) == false
  rescue URI::InvalidURIError, Socket::ResolutionError
    false
  end
end
