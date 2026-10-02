# frozen_string_literal: true

module Views
end

module Components
  extend Phlex::Kit
end

Mosscap.application.config.before_initialize do
  Mosscap.autoloaders.main.push_dir(
    Mosscap.root.join("app/views"), namespace: Views
  )

  Mosscap.autoloaders.main.push_dir(
    Mosscap.root.join("app/components"), namespace: Components
  )
end
