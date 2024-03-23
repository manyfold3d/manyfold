class ApplicationController < ActionController::Base
  include Pundit::Authorization
  after_action :verify_authorized, except: :index, unless: :active_admin_controller?
  after_action :verify_policy_scoped, only: :index, unless: :active_admin_controller?

  before_action :authenticate_user!
  before_action :check_for_first_use
  before_action :check_scan_status
  before_action :remember_ordering

  def index
    raise NotImplementedError
  end

  def authenticate_admin_user!
    authenticate_user!
    render plain: "401 Unauthorized", status: :unauthorized unless current_user.is_administrator?
  end

  def check_for_first_use
    redirect_to(edit_user_registration_path) if current_user&.reset_password_token == "first_use"
  end

  def check_scan_status
    @scan_in_progress = Delayed::Job.count > 0
  end

  def remember_ordering
    session["order"] ||= "name"
    session["order"] = params["order"] if params["order"]
  end

  def active_admin_controller?
    is_a?(ActiveAdmin::BaseController)
  end
end
