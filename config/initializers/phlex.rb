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

PLUGINS.each do
  plugin_component_dir = Rails.root.join("plugins/#{it}/app/components")
  Rails.autoloaders.main.push_dir(plugin_component_dir, namespace: Components) if plugin_component_dir.exist?
  plugin_view_dir = Rails.root.join("plugins/#{it}/app/views")
  Rails.autoloaders.main.push_dir(plugin_view_dir, namespace: Views) if plugin_view_dir.exist?
end
