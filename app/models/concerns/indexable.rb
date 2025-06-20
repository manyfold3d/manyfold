module Indexable
  extend ActiveSupport::Concern

  included do
    enum :indexable, {inherit: nil, no: 0, yes: 1}, suffix: true
    enum :ai_indexable, {inherit: nil, no: 0, yes: 1}, suffix: true

    scope :indexable, -> { SiteSettings.default_indexable ? all : none }
  end

  def indexable?
    SiteSettings.default_indexable
  end

  def ai_indexable?
    SiteSettings.default_ai_indexable
  end
end
