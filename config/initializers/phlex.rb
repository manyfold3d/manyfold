# frozen_string_literal: true

module Views
end

module Components
  extend Phlex::Kit
end

Rails.autoloaders.main.push_dir(
  Rails.root.join("app/views"), namespace: Views
)

Rails.autoloaders.main.push_dir(
  Rails.root.join("app/components"), namespace: Components
)

PLUGINS.each do |key, gemspec|
  plugin_component_dir = "#{gemspec.metadata[:path]}/app/components"
  Rails.autoloaders.main.push_dir(plugin_component_dir, namespace: Components) if Dir.exist?(plugin_component_dir)
  plugin_view_dir = "#{gemspec.metadata[:path]}/app/views"
  Rails.autoloaders.main.push_dir(plugin_view_dir, namespace: Views) if Dir.exist?(plugin_view_dir)
end
