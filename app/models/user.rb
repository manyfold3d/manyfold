require "uri"

class User < ApplicationRecord
  include Lister
  include Follower
  include CaberSubject
  include PublicIDable

  acts_as_federails_actor username_field: :public_id, name_field: :username, user_count_method: :user_count

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
    # Match existing users by email first
    user = find_by(auth_provider: nil, auth_uid: nil, email: auth.info.email)
    if user
      user.update!(
        auth_provider: auth.provider,
        auth_uid: auth.uid
      )
    else
      # Email isn't present, so let's match by ID
      user = find_or_create_by(auth_provider: auth.provider, auth_uid: auth.uid) do |user|
        user.email = auth.info.email
        # Find an unused username - get the first of a few options
        user.username = [
          auth.info.preferred_username,
          auth.info.nickname&.parameterize,
          auth.info.email&.split("@")&.[](0),
          # Fallback to any of the above with some random numbers on the end
          (auth.info.preferred_username || auth.info.nickname&.parameterize || auth.info.email&.split("@")&.[](0) || "") + SecureRandom.hex(2)
        ].compact.find { |u| !User.exists?(username: u) }
      end
    end
    user
  end

  def self.user_count(range)
    return User.count if range.nil?

    # Updated date isn't a great proxy for activity, but it'll do for now
    # We can improve this by using devise trackable to track logins at some point
    User.where(updated_at: range).count
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
