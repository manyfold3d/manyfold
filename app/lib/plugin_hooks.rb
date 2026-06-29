class PluginHooks
  include Singleton

  def initialize
    @hooks = {}
  end

  # Register a plugin to a specific hook
  # When the hook is called in the main application IO, the component will be rendered.
  # @param hook [Symbol] The name of the hook to attach the component to
  # @param component [Components::Base] A Phlex component that will be inserted at the hook location
  def self.register(hook, component)
    instance.send(:register, hook, component)
  end

  # Get a list of Phlex components that have been registered for the specified hook
  # @param hook [Symbol] The name of the hook
  def self.components_for(hook)
    instance.send(:components_for, hook)
  end

  private

  def register(hook, component)
    @hooks[hook] ||= []
    @hooks[hook] << component
  end

  def components_for(hook)
    @hooks[hook] || []
  end
end
