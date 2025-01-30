module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :slugify_name
  end

  private

  def slugify_name
    if persisted?
      self.slug = name.parameterize if name_changed?
    else
      self.slug ||= name&.parameterize
    end
  end
end
