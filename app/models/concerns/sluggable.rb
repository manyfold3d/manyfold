module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :slugify_name
  end

  private

  def slugify_name
    self.slug = name&.parameterize unless slug.presence
  end
end
