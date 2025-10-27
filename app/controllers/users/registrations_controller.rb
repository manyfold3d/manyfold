# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  rate_limit to: 3, within: 2.minutes, only: :create

  before_action :random_delay, only: [:create, :cancel]
  before_action :configure_sign_up_params, only: [:create]
  before_action :detect_if_first_use, only: [:edit, :update]
  before_action :load_languages, only: [:edit, :update]
  before_action :configure_account_update_params, only: [:update]
  skip_before_action :check_for_first_use, only: [:edit, :update]

  respond_to :html, :json

  # GET /resource/sign_up
  def new
    authorize User
    super
  end

  # GET /resource/edit
  def edit
    authorize current_user
    if @first_use
      render "first_use"
    else
      super
    end
  end

  # POST /users
  def create
    authorize User
    if AltchaSolution.verify_and_save(params.permit(:altcha)[:altcha])
      super do |user|
        opts = {}
        opts [:approved] = false if SiteSettings.approve_signups
        if SiteSettings.autocreate_creator_for_new_users
          creator_username = params.dig(:user, :creators_attributes, "0", :slug).presence || params.dig(:user, :creators_attributes, "0", :name)&.parameterize
          opts[:username] ||= "u;#{creator_username}" if creator_username
        end
        opts.compact!
        user.update(opts) unless opts.empty?
      end
      if @user.persisted?
        ModeratorMailer.with(user: @user).new_approval.deliver_later if SiteSettings.approve_signups && SiteSettings.email_configured?
      end
    else
      build_resource
      clean_up_passwords(resource)
      flash[:alert] = t(".altcha_failed")
      render :new, status: :unprocessable_content
    end
  end

  # PUT /resource
  def update
    authorize current_user
    if @first_use
      if current_user.update(account_update_params.merge(reset_password_token: nil))
        bypass_sign_in current_user
        redirect_to root_path, notice: t("devise.registrations.update.setup_complete")
      else
        render "first_use", status: :unprocessable_content
      end
    else
      super
    end
  end

  # DELETE /resource
  def destroy
    authorize current_user
    super
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  def cancel
    authorize :"users/registrations"
    super
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, creators_attributes: [:slug, :name]])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update) do |user|
      user.permit(
        :email,
        :username,
        :password,
        :password_confirmation,
        :current_password,
        :interface_language,
        :sensitive_content_handling,
        pagination_settings: [
          :models,
          :creators,
          :collections,
          :per_page
        ],
        tag_cloud_settings: [
          :threshold,
          :heatmap,
          :keypair,
          :sorting
        ],
        file_list_settings: [
          :hide_presupported_versions
        ],
        renderer_settings: [
          :grid_width,
          :grid_depth,
          :show_grid,
          :enable_pan_zoom,
          :background_colour,
          :object_colour,
          :render_style,
          :auto_load_max_size
        ],
        problem_settings: Problem::CATEGORIES,
        tour_state: {
          completed: {
            add: []
          }
        }
      )
    end
  end

  def detect_if_first_use
    if current_user.reset_password_token == "first_use"
      @first_use = true
      devise_parameter_sanitizer.permit(:account_update, keys: [:username])
    end
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    SiteSettings.approve_signups ? root_path : welcome_path
  end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after edit/update
  def after_update_path_for(resource)
    edit_user_registration_path
  end

  def pagination_json(settings)
    return nil unless settings
    {
      "models" => settings[:models] == "1",
      "creators" => settings[:creators] == "1",
      "collections" => settings[:collections] == "1",
      "per_page" => settings[:per_page].to_i
    }
  end

  def tag_cloud_json(settings)
    return nil unless settings
    {
      "threshold" => settings[:threshold].to_i,
      "heatmap" => settings[:heatmap] == "1",
      "keypair" => settings[:keypair] == "1",
      "sorting" => settings[:sorting].to_s
    }
  end

  def file_list_json(settings)
    return nil unless settings
    {
      "hide_presupported_versions" => settings[:hide_presupported_versions] == "1"
    }
  end

  def renderer_json(settings)
    return nil unless settings
    {
      "grid_width" => settings[:grid_width].to_i,
      "grid_depth" => settings[:grid_width].to_i, # Store width in both for now. See #834
      "show_grid" => settings[:show_grid] == "1",
      "enable_pan_zoom" => settings[:enable_pan_zoom] == "1",
      "background_colour" => settings[:background_colour],
      "object_colour" => settings[:object_colour],
      "render_style" => settings[:render_style],
      "auto_load_max_size" => settings[:auto_load_max_size].to_i
    }
  end

  def tour_state_json(current_state, data)
    return nil unless data
    {
      "completed" => (current_state["completed"] + data.dig("completed", "add")).uniq # Merge in added completions
    }
  end

  def load_languages
    @languages = [[t("devise.registrations.general_settings.interface_language.autodetect"), nil]].concat(
      I18n.available_locales.map { |locale| [I18nData.languages(locale)[locale.to_s.first(2).upcase.to_s]&.capitalize, locale] }
    )
  end

  def update_resource(resource, data)
    # Transform form data to correct types
    data[:pagination_settings] = pagination_json(data[:pagination_settings])
    data[:renderer_settings] = renderer_json(data[:renderer_settings])
    data[:tag_cloud_settings] = tag_cloud_json(data[:tag_cloud_settings])
    data[:file_list_settings] = file_list_json(data[:file_list_settings])
    data[:tour_state] = tour_state_json(resource.tour_state, data[:tour_state])
    data.compact!
    # Require password if important details have changed
    if (data[:email] && (data[:email] != resource.email)) || data[:password].present?
      resource.update_with_password(data)
    else
      resource.update_without_password(data.except(:email, :password, :password_confirmation, :current_password))
    end
  end
end
