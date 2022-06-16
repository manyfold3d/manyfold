class User < ApplicationRecord
  devise :database_authenticatable

  def to_param
    username
  end
end
