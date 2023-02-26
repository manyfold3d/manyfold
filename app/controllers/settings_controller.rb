class SettingsController < ApplicationController
  before_action :get_user
  before_action :check_owner_permission

  def show
  end

  def update
    if params[:pagination]
      @user.pagination_settings["models"] = params[:pagination][:models] == "1"
      @user.pagination_settings["creators"] = params[:pagination][:creators] == "1"
      @user.pagination_settings["per_page"] = params[:pagination][:per_page].to_i
    end
    if current_user.admin? && params[:model_tags]
      SiteSettings.model_tags_filter_stop_words = params[:model_tags][:filter_stop_words] == "1"
      SiteSettings.model_tags_tag_model_directory_name = params[:model_tags][:tag_model_directory_name] == "1"
      SiteSettings.model_tags_stop_words_locale = params[:model_tags][:stop_words_locale]
      SiteSettings.model_tags_custom_stop_words = params[:model_tags][:custom_stop_words].split
      SiteSettings.model_tags_auto_tag_new = params[:model_tags][:auto_tag_new]
      SiteSettings.model_path_prefix_template = params[:model_tags][:model_path_prefix_template]
      SiteSettings.model_tags_tag_model_path_prefix = params[:model_tags][:model_tags_tag_model_path_prefix]
      SiteSettings.model_path_suffix_model_id = params[:model_tags][:model_path_suffix_model_id]
    end
    if params[:renderer]
      @user.renderer_settings["grid_width"] = params[:renderer][:grid_width].to_i
      @user.renderer_settings["grid_depth"] = params[:renderer][:grid_width].to_i # Store width in both for now. See #834
      @user.renderer_settings["show_grid"] = params[:renderer][:show_grid] == "1"
      @user.renderer_settings["enable_pan_zoom"] = params[:renderer][:enable_pan_zoom] == "1"
      @user.renderer_settings["background_colour"] = params[:renderer][:background_colour]
      @user.renderer_settings["object_colour"] = params[:renderer][:object_colour]
      @user.renderer_settings["render_style"] = params[:renderer][:render_style]
    end
    @user.save!
    redirect_to user_settings_path(@user)
  end

  private

  def get_user
    @user = User.find_by(username: params[:user_id])
  end

  def check_owner_permission
    render plain: "401 Unauthorized", status: :unauthorized unless @user == current_user || current_user.admin?
  end
end
