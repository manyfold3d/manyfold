Rails.application.config.before_initialize do
  PLUGINS.each_pair do |key, gemspec|
    plugin_component_dir = "#{gemspec.metadata[:path]}/app/components"
    Rails.autoloaders.main.push_dir(plugin_component_dir, namespace: Components) if Dir.exist?(plugin_component_dir)
    plugin_view_dir = "#{gemspec.metadata[:path]}/app/views"
    Rails.autoloaders.main.push_dir(plugin_view_dir, namespace: Views) if Dir.exist?(plugin_view_dir)
  end
end
