PluginManager.each do |plugin_key, _spec|
  mount Object.const_get("#{plugin_key.camelize}::Engine") => "/#{plugin_key}"
end
