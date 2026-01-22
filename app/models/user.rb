require "uri"

class User < ApplicationRecord
  include Lister
  include Follower
  include CaberSubject
  include PublicIDable

  DEFAULT_TOUR_STATE = {"completed" => []}

  # Creator ownership relation used for auto-creation
  has_many :creators, -> { where("caber_relations.permission": "own") }, through: :caber_relations, source_type: "Creator", source: :object
  accepts_nested_attributes_for :creators

  has_many :notifications, as: :recipient, class_name: "Noticed::Notification", dependent: :destroy

  before_validation :set_json_field_defaults
  before_save :set_quota

  acts_as_federails_actor(
    username_field: :username,
    name_field: :username,
    user_count_method: :user_count
  )

  rolify
  devise :database_authenticatable,
    :registerable, :zxcvbnable,
    :rememberable, :recoverable,
    :lockable, :timeoutable,
    :invitable

  devise :omniauthable, omniauth_providers: %i[openid_connect] if SiteSettings.oidc_enabled?

  # Reduce validations if only safe settings are being changed
  with_options unless: :only_settings_changed? do
    validates :username,
      presence: true,
      uniqueness: {case_sensitive: false},
      format: {with: /\A[[:alnum:].\-_;]+\z/},
      multimodel_uniqueness: {punctuation_sensitive: false, case_sensitive: false, check: FederailsCommon::FEDIVERSE_USERNAMES}
    validates :email,
      presence: true,
      uniqueness: {case_sensitive: false},
      format: {with: URI::MailTo::EMAIL_REGEXP}
    validates :password,
      presence: true,
      confirmation: true,
      if: :password_required?
  end

  after_create :assign_default_role

  # Explicitly explain serialization for MariaDB
  serialize :pagination_settings, coder: CrossDbJsonSerializer
  serialize :renderer_settings, coder: CrossDbJsonSerializer
  serialize :tag_cloud_settings, coder: CrossDbJsonSerializer
  serialize :problem_settings, coder: CrossDbJsonSerializer
  serialize :file_list_settings, coder: CrossDbJsonSerializer
  serialize :tour_state, coder: CrossDbJsonSerializer

  attribute :sort_order, :integer # Explicit declaration of attribute so as not to break old data migrations
  enum :sort_order, {name: 0, recent: 1, updated: 2}, prefix: :sort_by, default: :name, validate: true

  has_many :access_grants, # rubocop:disable Rails/InverseOf
    class_name: "Doorkeeper::AccessGrant",
    foreign_key: :resource_owner_id,
    dependent: :delete_all

  has_many :access_tokens, # rubocop:disable Rails/InverseOf
    class_name: "Doorkeeper::AccessToken",
    foreign_key: :resource_owner_id,
    dependent: :delete_all

  has_many :oauth_applications,
    class_name: "Doorkeeper::Application",
    as: :owner,
    dependent: :delete_all,
    inverse_of: :owner

  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships

  attr_writer :skip_invitation

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
    listed?(file, :printed)
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
    # Link existing users by verified email first
    user = find_by(auth_provider: nil, auth_uid: nil, email: auth.info.email)
    if user
      raise OmniAuth::Strategies::OpenIDConnect::CallbackError, error: :email_unverified, reason: "Email not verified" unless auth.info.email_verified
      user.update!(
        auth_provider: auth.provider,
        auth_uid: auth.uid
      )
    else
      # Email isn't present, so let's match by ID
      user = find_or_create_by!(auth_provider: auth.provider, auth_uid: auth.uid) do |user|
        user.email = auth.info.email
        # Find an unused username - get the first of a few options
        user.username = [
          auth.info.preferred_username,
          auth.info.nickname,
          auth.info.email&.split("@")&.[](0),
          # Fallback to any of the above with some random numbers on the end
          (auth.info.preferred_username || auth.info.nickname || auth.info.email&.split("@")&.[](0) || "") + SecureRandom.hex(2)
        ]
          .compact
          .map { |u| u.gsub(/[^[:alnum:].\-_;]/, "-") }
          .find { |u| !User.exists?(username: u) }
      end
    end
    user
  end

  def self.user_count(range)
    return User.count if range.nil? # rubocop:disable Pundit/UsePolicyScope

    # Updated date isn't a great proxy for activity, but it'll do for now
    # We can improve this by using devise trackable to track logins at some point
    User.where(updated_at: range).count # rubocop:disable Pundit/UsePolicyScope
  end

  # Devise approval checks
  def active_for_authentication?
    super && approved?
  end

  def inactive_message
    approved? ? super : :not_approved
  end

  def self.send_reset_password_instructions(attributes = {})
    recoverable = find_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
    if recoverable.persisted?
      if recoverable.approved?
        recoverable.send_reset_password_instructions
      else
        recoverable.errors.add(:base, :not_approved)
      end
    end
    recoverable
  end

  def to_activitypub_object
    ActivityPub::UserSerializer.new(self).serialize
  end

  def public?
    true
  end

  # Quota is in MB and is referred to in the UI as file storage limits for clarity
  def quota
    quota_use_site_default ? SiteSettings.default_user_quota : attributes["quota"].to_i * 1.megabyte
  end

  def has_quota?
    !(attributes["quota"] == 0) && SiteSettings.enable_user_quota
  end

  def current_space_used
    permitted_models.with_permission("own").sum(&:size_on_disk)
  end

  def first_use?
    reset_password_token == "first_use"
  end

  def owns?(thing)
    has_permission_on?("own", thing)
  end

  def self.match!(identifier:, scope: User, invite: false)
    raise ActiveRecord::RecordNotFound if identifier.blank?
    query = case identifier
    when URI::MailTo::EMAIL_REGEXP
      {email: identifier}
    when /\A(acct:|@)([a-z0-9\-_.]+)(@(.*))?\z/io
      if SiteSettings.federation_enabled?
        actor = Federails::Actor.find_by_account(identifier) # rubocop:disable Rails/DynamicFindBy
        {id: actor&.entity&.id}
      else
        scope = scope.none
        {}
      end
    else
      {username: identifier}
    end
    scope.find_by! query
  rescue ActiveRecord::RecordNotFound
    if identifier =~ URI::MailTo::EMAIL_REGEXP && invite
      scope.find(User.invite!(email: identifier, skip_invitation: true).id)
    else
      raise
    end
  end

  def self.invite!(params)
    options = params
    options[:username] ||= "invite_#{SecureRandom.hex(8)}"
    super(options)
  end

  private

  def set_quota
    attributes["quota"] = SiteSettings.default_user_quota if try(:quota_use_site_default)
  end

  def has_any_role_of?(*args)
    args.map { |it| has_role? it }.any?
  end

  def assign_default_role
    return unless roles.empty?
    default_roles = [:member, SiteSettings.default_signup_role.to_sym].uniq
    default_roles.each { |it| add_role(it) }
  end

  def password_required?
    return false if try(:auth_provider) && try(:auth_uid)
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  def weak_words
    ["manyfold", username]
  end

  def set_json_field_defaults
    self.pagination_settings ||= SiteSettings::UserDefaults::PAGINATION
    self.renderer_settings ||= SiteSettings::UserDefaults::RENDERER
    self.tag_cloud_settings ||= SiteSettings::UserDefaults::TAG_CLOUD
    self.problem_settings ||= Problem::DEFAULT_SEVERITIES
    self.file_list_settings ||= SiteSettings::UserDefaults::FILE_LIST
    self.tour_state ||= DEFAULT_TOUR_STATE
  end

  def only_settings_changed?
    return false unless changed?
    settings_attributes = [
      "sensitive_content_handling",
      "interface_language",
      "sort_order",
      "pagination_settings",
      "renderer_settings",
      "tag_cloud_settings",
      "problem_settings",
      "file_list_settings",
      "tour_state"
    ].freeze
    (changed - settings_attributes).empty?
  end
end
