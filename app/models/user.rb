class User < ApplicationRecord
  rolify
  devise :database_authenticatable, :registerable, :validatable

  acts_as_favoritor

  validates :username,
    presence: true,
    uniqueness: {case_sensitive: false},
    format: {with: /\A[[:alnum:]]{3,}\z/}

  after_create :assign_default_role

  def to_param
    username
  end

  def printed?(file)
    favorited?(file, scope: :printed)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "id", "updated_at", "username"]
  end

  private

  def assign_default_role
    add_role(:viewer) if roles.blank?
  end
end
