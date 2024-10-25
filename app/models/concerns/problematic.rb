module Problematic
  extend ActiveSupport::Concern

  included do
    has_many :problems, as: :problematic, dependent: :destroy
  end
end
