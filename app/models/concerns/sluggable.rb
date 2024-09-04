module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :slugify_name, if: :name_changed?
  end

  private

  def slugify_name
    self.slug = name.parameterize
  end
end
