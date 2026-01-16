class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include BetterContentSecurityPolicy::HasContentSecurityPolicy

  after_action :verify_authorized, except: :index, unless: -> { respond_to?(:fasp_client_controller?) }
  after_action :verify_policy_scoped, only: :index, unless: -> { respond_to?(:fasp_client_controller?) }
  after_action :set_content_security_policy_header, if: -> { request.format.html? }

  before_action :authenticate_user!, unless: -> { SiteSettings.multiuser_enabled? || has_signed_id? }
  around_action :switch_locale, if: -> { request.format.html? }
  before_action :check_for_first_use
  before_action :show_security_alerts
  before_action :check_scan_status
  before_action :restore_failed_search

  protect_from_forgery with: :null_session, if: :is_api_request?

  rescue_from ScopedSearch::QueryNotSupported, with: -> {
    flash[:alert] = t("application.search_error")
    flash[:query] = params[:q]
    redirect_back_or_to root_path
  }

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
    authenticate_user! if User.count == 0 # rubocop:disable Pundit/UsePolicyScope
    redirect_to(edit_user_registration_path) if current_user&.first_use?
  end

  def check_scan_status
    @scan_in_progress = Sidekiq::Queue.new("scan").size > 0
  end

  private

  def restore_failed_search
    @query ||= flash[:query]
  end

  def is_api_request?
    request.format.manyfold_api_v0?
  end

  def has_signed_id?
    params[:sig] && ApplicationRecord.signed_id_verifier.valid_message?(params[:sig])
  end

  def img_src
    host = begin
      SiteSettings.site_icon ? URI.parse(SiteSettings.site_icon).host : nil
    rescue
      nil
    end
    [
      :self,
      :data,
      host,
      "https://cdn.jsdelivr.net",
      "https://raw.githubusercontent.com",
      SiteSettings.federation_enabled? ? :https : nil
    ].compact
  end

  def frame_src
    [
      :self,
      SiteSettings.federation_enabled? ? :https : nil
    ].compact
  end

  def configure_content_security_policy
    return if Rails.env.test?

    # Standard security policy
    content_security_policy.default_src :self
    content_security_policy.connect_src :self
    content_security_policy.frame_ancestors :self
    content_security_policy.frame_src(*frame_src)
    content_security_policy.font_src :self, "https://cdn.jsdelivr.net", "https://fonts.gstatic.com"
    content_security_policy.img_src(*img_src)
    content_security_policy.object_src :none
    content_security_policy.script_src :self
    content_security_policy.style_src :self
    content_security_policy.style_src_attr :unsafe_inline
    content_security_policy.style_src_elem :self, "nonce-#{content_security_policy_nonce}", "https://fonts.googleapis.com"
    # Add library origins
    origins = Library.all.filter_map(&:storage_origin) # rubocop:disable Pundit/UsePolicyScope
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
    I18n.with_locale(locale.presence, &action)
  end

  def show_security_alerts
    return unless current_user&.is_administrator?
    return if ENV.fetch("SUDO_RUN_UNSAFELY", nil) === "enabled"
    flash.now[:alert] = t("security.running_as_root_html") if Process.uid == 0
  end

  def random_delay
    # Not sure how secure this is; it's used to help with timing attacks on login ID lookups
    # by adding a random 0-2 second delay into the response. There is probably a better way.
    sleep Random.new.rand(2.0)
  end

  def user_not_authorized
    if current_user
      raise ActiveRecord::RecordNotFound
    else
      redirect_to new_session_path(:user)
    end
  end

  def set_indexable(content)
    arr = Array(content)
    @indexing_directives = [
      ("noindex" unless arr.map(&:indexable?).all?),
      ("noai noimageai" unless arr.map(&:ai_indexable?).all?)
    ].compact.join(" ")
    response.headers["X-Robots-Tag"] = @indexing_directives if @indexing_directives.presence
  end

  def send_file_content(attachment, disposition: :attachment, derivative: nil)
    head :not_found and return if attachment.nil?
    # Check if we can send a direct URL
    redirect_to(attachment.url, allow_other_host: true) if /https?:\/\//.match?(attachment.url)
    # Otherwise provide a direct download
    status, headers, body = attachment.to_rack_response(disposition: disposition)
    self.status = status
    self.headers.merge!(headers)
    self.response_body = body
  rescue Errno::ENOENT
    head :internal_server_error
  end
end
