module Indexable
  extend ActiveSupport::Concern

  included do
    scope :indexable, -> { SiteSettings.default_indexable ? all : none }
  end

  def indexable?
    SiteSettings.default_indexable
  end

  def ai_indexable?
    SiteSettings.default_ai_indexable
  end
end
