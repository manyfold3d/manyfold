class PluginsController < ApplicationController
  layout "settings"

  def index
    skip_policy_scope
    @plugins = PLUGINS.values
    respond_to do |format|
      format.html { render Views::Plugins::Index.new(plugins: @plugins) }
    end
  end
end
