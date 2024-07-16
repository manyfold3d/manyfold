# frozen_string_literal: true

class AddNewDefaultsToRendererSettings < ActiveRecord::Migration[7.0]
  def up
    User.find_each do |user|
      user.update(
        renderer_settings: SiteSettings::UserDefaults::RENDERER.merge(user.renderer_settings)
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
