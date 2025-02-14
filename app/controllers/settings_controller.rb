class SettingsController < ApplicationController
  before_action :check_owner_permission

  def update
    # Save site-wide settings if user is an admin
    update_folder_settings(params[:folders])
    update_appearance_settings(params[:appearance])
    update_file_settings(params[:files])
    update_tagging_settings(params[:model_tags])
    update_multiuser_settings(params[:multiuser])
    update_analysis_settings(params[:analysis])
    update_usage_settings(params[:usage])
    redirect_back_or_to settings_path, notice: t(".success")
  end

  private

  def update_folder_settings(settings)
    return unless settings
    SiteSettings.model_path_template = settings[:model_path_template].gsub(/^\//, "") # Remove leading slashes
    SiteSettings.parse_metadata_from_path = settings[:parse_metadata_from_path]
    SiteSettings.safe_folder_names = settings[:safe_folder_names]
  end

  def update_file_settings(settings)
    return unless settings
    unless settings[:model_ignored_files].split("\n").any? { |p| p.to_regexp.nil? }
      SiteSettings.model_ignored_files = settings[:model_ignored_files]
    end
  end

  def update_appearance_settings(settings)
    return unless settings
    SiteSettings.theme = settings[:theme]
  end

  def update_tagging_settings(settings)
    return unless settings
    SiteSettings.model_tags_filter_stop_words = settings[:filter_stop_words] == "1"
    SiteSettings.model_tags_tag_model_directory_name = settings[:tag_model_directory_name] == "1"
    SiteSettings.model_tags_stop_words_locale = settings[:stop_words_locale]
    SiteSettings.model_tags_custom_stop_words = settings[:custom_stop_words].split
    SiteSettings.model_tags_auto_tag_new = settings[:auto_tag_new]
  end

  def update_analysis_settings(settings)
    return unless settings
    SiteSettings.analyse_manifold = settings[:manifold] == "1"
  end

  def update_multiuser_settings(settings)
    return unless settings
    SiteSettings.approve_signups = (settings[:approve_signups])
    SiteSettings.default_viewer_role = (settings[:default_viewer_role].presence)
  end

  def update_usage_settings(settings)
    return unless settings
    (settings[:report] == "1") ? UsageReport.enable! : UsageReport.disable!
  end

  def check_owner_permission
    authorize :settings
  end
end
