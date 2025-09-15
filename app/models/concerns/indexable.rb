module Indexable
  extend ActiveSupport::Concern

  included do
    validates :indexable, inclusion: {in: [nil, "no", "yes"]}
    validates :ai_indexable, inclusion: {in: [nil, "no", "yes"]}

    normalizes :indexable, with: ->(it) { (it == "inherit") ? nil : it }
    normalizes :ai_indexable, with: ->(it) { (it == "inherit") ? nil : it }
  end

  def public_and_indexable?
    respond_to?(:indexable) && indexable? && public?
  end

  def indexable?
    case indexable
    when nil
      inherited_indexable?
    when "yes"
      true
    else
      false
    end
  end

  def ai_indexable?
    case ai_indexable
    when nil
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
