class User < ApplicationRecord
  rolify
  devise :database_authenticatable, :registerable, :secure_validatable

  acts_as_favoritor

  validates :username,
    presence: true,
    uniqueness: {case_sensitive: false},
    format: {with: /\A[[:alnum:]]{3,}\z/}

  validates :email,
    presence: true,
    uniqueness: {case_sensitive: false}

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

  def is_administrator?
    has_any_role_of? :administrator
  end

  def is_editor?
    has_any_role_of? :administrator, :editor
  end

  def is_contributor?
    has_any_role_of? :administrator, :editor, :contributor
  end

  def is_viewer?
    has_any_role_of? :administrator, :editor, :contributor, :viewer
  end

  private

  def has_any_role_of?(*args)
    args.map { |x| has_role? x }.any?
  end

  def assign_default_role
    add_role(:viewer) if roles.blank?
  end
end
