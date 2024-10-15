require "uri"

class User < ApplicationRecord
  include Lister
  include Follower
  include CaberSubject

  acts_as_federails_actor username_field: :username, name_field: :username

  rolify
  devise :database_authenticatable,
    :registerable, :zxcvbnable,
    :rememberable, :recoverable,
    :lockable, :timeoutable

  devise :omniauthable, omniauth_providers: %i[openid_connect] if SiteSettings.oidc_enabled?

  validates :username,
    presence: true,
    uniqueness: {case_sensitive: false},
    format: {with: /\A[[:alnum:]]{3,}\z/}

  validates :email,
    presence: true,
    uniqueness: {case_sensitive: false},
    format: {with: URI::MailTo::EMAIL_REGEXP}

  validates :password,
    presence: true,
    confirmation: true,
    if: :password_required?

  after_create :assign_default_role

  # Explicitly explain serialization for MariaDB
  attribute :pagination_settings, :json
  attribute :renderer_settings, :json
  attribute :tag_cloud_settings, :json
  attribute :problem_settings, :json
  attribute :file_list_settings, :json

  def federails_name
    username
  end

  def to_param
    username
  end

  def self.find_param(param)
    find_by!(username: param)
  end

  def printed?(file)
    listed?(file, scope: :printed)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "id", "updated_at", "username"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["role"]
  end

  def is_administrator?
    has_any_role_of? :administrator
  end

  def is_moderator?
    has_any_role_of? :administrator, :moderator
  end

  def is_contributor?
    has_any_role_of? :administrator, :moderator, :contributor
  end

  def is_member?
    has_any_role_of? :administrator, :moderator, :contributor, :member
  end

  def problem_severity(category)
    problem_settings[category.to_s]&.to_sym || Problem::DEFAULT_SEVERITIES[category.to_sym]
  end

  def self.from_omniauth(auth)
    find_or_create_by(auth_provider: auth.provider, auth_uid: auth.uid) do |user|
      user.email = auth.info.email
      user.username = auth.info.preferred_username || auth.info.nickname&.parameterize || auth.info.email.split("@")[0]
    end
  end

  private

  def has_any_role_of?(*args)
    args.map { |x| has_role? x }.any?
  end

  def assign_default_role
    add_role(:member) if roles.blank?
  end

  def password_required?
    return false if auth_provider && auth_uid
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  def weak_words
    ["manyfold", username]
  end
end
