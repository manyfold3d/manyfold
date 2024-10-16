class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include BetterContentSecurityPolicy::HasContentSecurityPolicy
  after_action :verify_authorized, except: :index, unless: :active_admin_controller?
  after_action :verify_policy_scoped, only: :index, unless: :active_admin_controller?
  after_action :set_content_security_policy_header, if: -> { request.format.html? }

  before_action :authenticate_user!, if: -> { !SiteSettings.multiuser_enabled? }
  around_action :switch_locale
  before_action :check_for_first_use
  before_action :show_security_alerts
  before_action :check_scan_status
  before_action :remember_ordering

  unless Rails.env.test?
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  def index
    raise NotImplementedError
  end

  def authenticate_admin_user!
    authenticate_user!
    render plain: "401 Unauthorized", status: :unauthorized unless current_user.is_administrator?
  end

  def check_for_first_use
    authenticate_user! if User.count == 0
    redirect_to(edit_user_registration_path) if current_user&.reset_password_token == "first_use"
  end

  def check_scan_status
    @scan_in_progress = Sidekiq::Queue.new("scan").size > 0
  end

  def remember_ordering
    session["order"] ||= "name"
    session["order"] = params["order"] if params["order"]
  end

  def active_admin_controller?
    is_a?(ActiveAdmin::BaseController)
  end

  private

  def img_src
    url = ENV.fetch "SITE_ICON", nil
    url ? URI.parse(url).host : nil
    [:self, :data, url].compact
  end

  def configure_content_security_policy
    # Standard security policy
    content_security_policy.default_src :self
    content_security_policy.connect_src :self
    content_security_policy.frame_ancestors :self
    content_security_policy.frame_src :self
    content_security_policy.font_src :self, "https://cdn.jsdelivr.net"
    content_security_policy.img_src(*img_src)
    content_security_policy.object_src :none
    content_security_policy.script_src :self
    content_security_policy.style_src :self
    content_security_policy.style_src_attr :unsafe_inline
    # Add libary origins
    origins = Library.all.filter_map(&:storage_origin)
    content_security_policy.img_src(*origins)
    content_security_policy.connect_src(*origins)
    # If we're using Scout DevTrace in local development, we need to allow a load
    # of inline stuff, so we need to add that and NOT add the nonce
    if Rails.env.development? && ENV.fetch("SCOUT_DEV_TRACE", false) === "true"
      scout_csp = [:unsafe_inline, "https://apm.scoutapp.com", "https://scoutapm.com"]
      content_security_policy.img_src(*scout_csp)
      content_security_policy.script_src(*scout_csp)
      content_security_policy.style_src(*scout_csp)
      content_security_policy.connect_src(*scout_csp)
      content_security_policy.frame_src(*scout_csp)
    else
      content_security_policy.script_src "nonce-#{content_security_policy_nonce}"
    end
  end

  def switch_locale(&action)
    locale = current_user&.interface_language || request.env["rack.locale"]
    I18n.with_locale(locale, &action)
  end

  def show_security_alerts
    return unless current_user&.is_administrator?
    flash.now[:alert] = t("security.running_as_root_html") if Process.uid == 0
  end

  def random_delay
    # Not sure how secure this is; it's used to help with timing attacks on login ID lookups
    # by adding a random 0-2 second delay into the response. There is probably a better way.
    sleep Random.new.rand(2.0)
  end

  private

  def user_not_authorized
    if current_user
      raise ActiveRecord::RecordNotFound
    else
      redirect_to new_session_path(:user)
    end
  end
end
