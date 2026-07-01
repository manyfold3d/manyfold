PluginManager.all.keys.each do |plugin_key|
  mount Object.const_get("#{plugin_key.camelize}::Engine") => "/#{plugin_key}"
end
