module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :slugify_name, if: -> { respond_to? :slug }
  end

  private

  def slugify_name
    self.slug = name&.parameterize unless slug.presence
  end
end
