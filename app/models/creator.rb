class Creator < ApplicationRecord
  has_many :models, dependent: :nullify
end
