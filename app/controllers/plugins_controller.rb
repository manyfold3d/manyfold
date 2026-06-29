class PluginsController < ApplicationController
  layout "settings"

  def index
    skip_policy_scope
    @plugins = PLUGINS.values
    respond_to do |format|
      format.html { render Views::Plugins::Index.new(plugins: @plugins) }
    end
  end

  def create
    # No specific authorisation needed other than "user is admin" which is already checked by this point
    skip_authorization
    # Process the uploaded file
    extract_plugin
    # Back we go
    redirect_to settings_plugins_path
  end

  private

  def extract_plugin
    # Set the flag that a restart is now needed
    Rails.cache.write("restart_required", true)
  end
end
