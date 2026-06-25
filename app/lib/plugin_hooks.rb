class PluginHooks
  include Singleton

  def initialize
    @hooks = {}
  end

  def register(hook, component)
    @hooks[hook] ||= []
    @hooks[hook] << component
  end

  def self.register(hook, component)
    instance.register(hook, component)
  end

  def components_for(hook)
    @hooks[hook] || []
  end
end
