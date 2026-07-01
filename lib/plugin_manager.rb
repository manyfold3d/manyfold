class PluginManager
  include Singleton

  attr_accessor :plugins

  def initialize
    @plugins = {}
    @hooks = {}
  end

  def self.load!
    instance.send :load!
  end

  def self.require!
    each do |name, metadata|
      require name
    end
  end

  def self.each
    instance.plugins.each_pair do |name, metadata|
      yield name, metadata
    end
  end

  def self.all
    instance.plugins
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

  # Check whether we can self-install plugins
  def self.can_install_plugins?
    Rails.root.join("plugins").writable?
  end

  private

  def load!
    # Require any engines inside plugins folder
    plugins_path = ENV.fetch("PLUGINS_PATH", File.expand_path("../plugins", __dir__))
    Dir.glob(File.join(plugins_path, "*/*.gemspec")).each do |gemspec|
      directory = File.dirname(gemspec)
      plugin_key = File.basename(gemspec, ".*")

      # Load metadata
      spec = Gem::Specification.load(gemspec.to_s)
      if spec.metadata["manyfold_version"]
        spec.metadata[:path] = directory
        @plugins[plugin_key] = spec
        # Add to load path
        $: << directory
        $: << File.join(directory, "lib")
      end
    end
  end

  def register(hook, component)
    @hooks[hook] ||= []
    @hooks[hook] << component
  end

  def components_for(hook)
    @hooks[hook] || []
  end
end
