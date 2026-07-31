# frozen_string_literal: true

module Views
end

module Components
  extend Phlex::Kit
end

Amiko.application.config.before_initialize do
  Amiko.autoloaders.main.push_dir(
    Amiko.root.join("app/views"), namespace: Views
  )

  Amiko.autoloaders.main.push_dir(
    Amiko.root.join("app/components"), namespace: Components
  )
end
