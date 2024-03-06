class User < ApplicationRecord
  begin
    if Flipper.enabled? :multiuser
      devise :database_authenticatable, :registerable, :validatable
    else
      devise :database_authenticatable
    end
  rescue ActiveRecord::StatementInvalid
    # If we've not migrated Flipper yet, we'll get an exception, which we can swallow
  end

  acts_as_favoritor

  validates :username,
    presence: true,
    uniqueness: {case_sensitive: false},
    format: {with: /\A[[:alnum:]]{3,}\z/}

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
