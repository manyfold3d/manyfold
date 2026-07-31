# frozen_string_literal: true

# Forked from rails/rails/railties/lib/rails/

require "pathname"

require "active_support"
require "active_support/core_ext/kernel/reporting"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/array/extract_options"
require "active_support/core_ext/object/blank"

require "rails/version"
require "rails/deprecator"
require "rails/application"
require "rails/backtrace_cleaner"

require "active_support/railtie"
require "action_dispatch/railtie"

# UTF-8 is the default internal and external encoding.
silence_warnings do
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

# :include: ../README.rdoc
module Rails
  extend ActiveSupport::Autoload
  extend ActiveSupport::Benchmarkable

  autoload :Info
  autoload :InfoController
  autoload :MailersController
  autoload :WelcomeController

  eager_autoload do
    autoload :HealthController
    autoload :PwaController
  end

  class << self
    @application = @app_class = nil

    attr_writer :application
    attr_accessor :app_class, :cache, :logger
    def application
      @application ||= (app_class.instance if app_class)
    end

    delegate :initialize!, :initialized?, to: :application

    # The Configuration instance used to configure the \Amiko environment
    def configuration
      application.config
    end

    def backtrace_cleaner
      @backtrace_cleaner ||= Amiko::BacktraceCleaner.new
    end

    # Returns a Pathname object of the current \Amiko project,
    # otherwise it returns +nil+ if there is no project:
    #
    #   Amiko.root
    #     # => #<Pathname:/Users/someuser/some/path/project>
    def root
      application && application.config.root
    end

    # Returns the current \Amiko environment.
    #
    #   Amiko.env # => "development"
    #   Amiko.env.development? # => true
    #   Amiko.env.production? # => false
    #   Amiko.env.local? # => true              true for "development" and "test", false for anything else
    def env
      @_env ||= ActiveSupport::EnvironmentInquirer.new(ENV["RAILS_ENV"].presence || ENV["RACK_ENV"].presence || "development")
    end

    # Sets the \Amiko environment.
    #
    #   Amiko.env = "staging" # => "staging"
    def env=(environment)
      @_env = ActiveSupport::EnvironmentInquirer.new(environment)
    end

    # Returns the ActiveSupport::ErrorReporter of the current \Amiko project,
    # otherwise it returns +nil+ if there is no project.
    #
    #   Amiko.error.handle(IOError) do
    #     # ...
    #   end
    #   Amiko.error.report(error)
    def error
      ActiveSupport.error_reporter
    end

    # Returns all \Amiko groups for loading based on:
    #
    # * The \Amiko environment;
    # * The environment variable RAILS_GROUPS;
    # * The optional envs given as argument and the hash with group dependencies;
    #
    #  Amiko.groups assets: [:development, :test]
    #  # => [:default, "development", :assets] for Amiko.env == "development"
    #  # => [:default, "production"]           for Amiko.env == "production"
    def groups(*groups)
      hash = groups.extract_options!
      env = Amiko.env
      groups.unshift(:default, env)
      groups.concat ENV["RAILS_GROUPS"].to_s.split(",")
      groups.concat hash.map { |k, v| k if v.map(&:to_s).include?(env) }
      groups.compact!
      groups.uniq!
      groups
    end

    # Returns a Pathname object of the public folder of the current
    # \Amiko project, otherwise it returns +nil+ if there is no project:
    #
    #   Amiko.public_path
    #     # => #<Pathname:/Users/someuser/some/path/project/public>
    def public_path
      application && Pathname.new(application.paths["public"].first)
    end

    def autoloaders
      application.autoloaders
    end
  end
end

Amiko = Rails
