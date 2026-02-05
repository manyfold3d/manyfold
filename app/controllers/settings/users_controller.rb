class Settings::UsersController < ApplicationController
  before_action :get_user, except: [:index, :new, :create]
  before_action :get_available_roles, only: [:new, :create, :edit, :update]
  respond_to :html

  def index
    @users = policy_scope(User).active.includes([:roles])
    @users = apply_sort_order(@users)
    @users = @users.page(params[:page]&.to_i || 1).per(params[:per_page]&.to_i || 25)
    render layout: "settings"
  end

  def show
    render layout: "settings"
  end

  def new
    authorize(User)
    @user = User.new
    @user.send :assign_default_role
    render layout: "settings"
  end

  def edit
    render layout: "settings"
  end

  def create
    authorize(User)
    password = helpers.random_password
    # Create user with a random password if one isn't provided
    @user = User.create({
      "password" => password,
      "password_confirmation" => password,
      "quota" => SiteSettings.default_user_quota,
      "quota_use_site_default" => true
    }.merge(user_params))
    if @user.valid?
      @user.send_reset_password_instructions if SiteSettings.email_configured?
      redirect_to [:settings, @user], notice: t(".success")
    else
      render :new, layout: "settings", status: :unprocessable_content
    end
  end

  def update
    if params[:reset]
      @user.send_reset_password_instructions
      redirect_to [:settings, @user], notice: t(".reset_link_sent")
    elsif params[:approve]
      @user.update(approved: true)
      UserMailer.with(user: @user).account_approved.deliver_later if SiteSettings.email_configured?
      redirect_to [:settings, @user], notice: t(".approved")
    elsif @user.update(user_params)
      redirect_to [:settings, @user], notice: t(".success")
    else
      render :edit, layout: "settings", status: :unprocessable_content
    end
  end

  def destroy
    @user.destroy
    redirect_to settings_users_path, notice: t(".success")
  end

  private

  def get_available_roles
    @available_roles = policy_scope(Role).all
  end

  def get_user
    @user = policy_scope(User).find_param(params[:id])
    authorize @user
  end

  def user_params
    filtered = params.expect(
      user: [
        :email,
        :username,
        :password,
        :password_confirmation,
        :quota,
        :quota_use_site_default,
        role_ids: []
      ]
    )
    # Filter out admin privilege for anyone but admins
    unless current_user&.is_administrator?
      filtered[:role_ids]&.delete_if { |it| @available_roles.map(&:id).exclude? it.to_i }
    end
    filtered
  end

  def apply_sort_order(scope)
    case params[:order]
    when "name"
      scope.order(username: :asc)
    when "recent"
      scope.order(created_at: :desc)
    else # default to "pending"
      scope.order(approved: :asc, created_at: :desc)
    end
  end
end
