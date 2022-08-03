class User < ApplicationRecord
  devise :database_authenticatable
  acts_as_favoritor

  def to_param
    username
  end
end
