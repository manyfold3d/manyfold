class Link < ApplicationRecord
  belongs_to :linkable, polymorphic: true

  def host
    URI.parse(url).host
  end

  def site
    PublicSuffix.parse(host).sld.to_sym
  end
end
