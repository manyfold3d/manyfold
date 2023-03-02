module ActsAsTaggableOn
  class Tag < ApplicationRecord
    attribute :notes, :string
    attribute :caption, :string
  end
end
