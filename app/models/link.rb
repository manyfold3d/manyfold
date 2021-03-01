class Link < ApplicationRecord
  belongs_to :linkable, polymorphic: true
end
