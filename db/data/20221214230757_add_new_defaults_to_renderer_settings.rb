# frozen_string_literal: true

class AddNewDefaultsToRendererSettings < ActiveRecord::Migration[7.0]
  def up
    User.all.each do |user|
      user.update(
        renderer_settings: {
          "show_grid" => true,
          "enable_pan_zoom" => false,
          "background_colour" => "#000000",
          "object_colour" => "#cccccc",
          "render_style" => "normals"
        }.merge(user.renderer_settings)
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
