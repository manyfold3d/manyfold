class Problem < ApplicationRecord
  belongs_to :problematic, polymorphic: true

  enum :type, [:missing]
end
