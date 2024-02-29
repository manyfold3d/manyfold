class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :validatable
  acts_as_favoritor

  def to_param
    username
  end

  def printed?(file)
    favorited?(file, scope: :printed)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "id", "updated_at", "username"]
  end
end
