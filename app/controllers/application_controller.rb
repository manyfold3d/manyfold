class ApplicationController < ActionController::Base
  include Pundit::Authorization
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  before_action :auto_login_single_user
  before_action :authenticate_user!
  before_action :check_scan_status
  before_action :remember_ordering

  def index
    raise NotImplementedError
  end

  def auto_login_single_user
    sign_in(:user, User.first) unless Flipper.enabled? :multiuser
  end

  def authenticate_admin_user!
    authenticate_user!
    render plain: "401 Unauthorized", status: :unauthorized unless current_user.admin?
  end

  def check_scan_status
    @scan_in_progress = Delayed::Job.count > 0
  end

  def remember_ordering
    session["order"] ||= "name"
    session["order"] = params["order"] if params["order"]
  end
end
