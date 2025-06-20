module Indexable
  extend ActiveSupport::Concern

  def indexable?
    SiteSettings.default_indexable
  end

  def ai_indexable?
    SiteSettings.default_ai_indexable
  end
end
