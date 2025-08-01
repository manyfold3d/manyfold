class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Default find_param implementation
  # just the same as standard find()
  def self.find_param(param)
    find(param)
  end
end
