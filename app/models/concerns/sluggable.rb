module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :slugify_name, if: -> { respond_to? :slug }
  end

  private

  def slugify_name
    self.slug = name&.parameterize if name_changed? && (slug.blank? || !slug_changed?)
  end
end
