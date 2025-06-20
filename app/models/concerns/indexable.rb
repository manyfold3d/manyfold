module Indexable
  extend ActiveSupport::Concern

  included do
    enum :indexable, {inherit: nil, no: 0, yes: 1}, suffix: true
    enum :ai_indexable, {inherit: nil, no: 0, yes: 1}, suffix: true

    scope :indexable, -> { SiteSettings.default_indexable ? all : none }
  end

  def indexable?
    case indexable
    when "inherit"
      inherited_indexable?
    when "yes"
      true
    else
      false
    end
  end

  def ai_indexable?
    case ai_indexable
    when "inherit"
      inherited_ai_indexable?
    when "yes"
      true
    else
      false
    end
  end

  def inherited_indexable?
    SiteSettings.default_indexable
  end

  def inherited_ai_indexable?
    SiteSettings.default_ai_indexable
  end
end
