class Relationship < ApplicationRecord
  belongs_to :subject, polymorphic: true
  belongs_to :objekt, polymorphic: true

  validates :predicate, uniqueness: {scope: [:subject, :objekt]}
end
