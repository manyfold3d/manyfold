module Indexable
  extend ActiveSupport::Concern

  included do
    enum :indexable, {inherit: nil, no: 0, yes: 1}, suffix: true
    enum :ai_indexable, {inherit: nil, no: 0, yes: 1}, suffix: true
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
    if is_a?(Collection) && collection
      collection.indexable?
    elsif respond_to?(:creator) && creator
      creator.indexable?
    else
      SiteSettings.default_indexable
    end
  end

  def inherited_ai_indexable?
    if is_a?(Collection) && collection
      collection.ai_indexable?
    elsif respond_to?(:creator) && creator
      creator.ai_indexable?
    else
      SiteSettings.default_ai_indexable
    end
  end
end
