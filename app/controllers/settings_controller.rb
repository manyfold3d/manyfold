class SettingsController < ApplicationController
  before_action :get_user
  before_action :check_owner_permission

  def show
  end

  def update
    # Save personal settings
    update_pagination_settings(params[:pagination])
    update_renderer_settings(params[:renderer])
    update_tag_cloud_settings(params[:tag_cloud])
    @user.save!
    # Save site-wide settings if user is an admin
    if current_user.admin?
      update_folder_settings(params[:folders])
      update_tagging_settings(params[:model_tags])
    end
    redirect_to user_settings_path(@user)
  end

  private

  def update_pagination_settings(settings)
    return unless settings
    @user.pagination_settings = {
      "models" => settings[:models] == "1",
      "creators" => settings[:creators] == "1",
      "collections" => settings[:collections] == "1",
      "per_page" => settings[:per_page].to_i
    }
  end

  def update_tag_cloud_settings(settings)
    return unless settings
    @user.tag_cloud_settings = {
      "threshold" => settings[:threshold].to_i,
      "heatmap" => settings[:heatmap] == "1",
      "keypair" => settings[:keypair] == "1",
      "sorting" => settings[:sorting],
      "hide_unrelated" => settings[:hide_unrelated] == "1"
    }
  end

  def update_renderer_settings(settings)
    return unless settings
    @user.renderer_settings = {
      "grid_width" => settings[:grid_width].to_i,
      "grid_depth" => settings[:grid_width].to_i, # Store width in both for now. See #834
      "show_grid" => settings[:show_grid] == "1",
      "enable_pan_zoom" => settings[:enable_pan_zoom] == "1",
      "background_colour" => settings[:background_colour],
      "object_colour" => settings[:object_colour],
      "render_style" => settings[:render_style]
    }
  end

  def update_folder_settings(settings)
    return unless settings
    SiteSettings.model_path_template = settings[:model_path_template].gsub(/^\//, "") # Remove leading slashes
    SiteSettings.parse_metadata_from_path = settings[:parse_metadata_from_path]
    SiteSettings.safe_folder_names = settings[:safe_folder_names]
  end

  def update_tagging_settings(settings)
    return unless settings
    SiteSettings.model_tags_filter_stop_words = settings[:filter_stop_words] == "1"
    SiteSettings.model_tags_tag_model_directory_name = settings[:tag_model_directory_name] == "1"
    SiteSettings.model_tags_stop_words_locale = settings[:stop_words_locale]
    SiteSettings.model_tags_custom_stop_words = settings[:custom_stop_words].split
    SiteSettings.model_tags_auto_tag_new = settings[:auto_tag_new]
  end

  def get_user
    @user = User.find_by(username: params[:user_id])
  end

  def check_owner_permission
    render plain: "401 Unauthorized", status: :unauthorized unless @user == current_user || current_user.admin?
  end
end
