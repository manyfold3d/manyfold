# frozen_string_literal: true

class MoveScaleFactorIntoNote < ActiveRecord::Migration[7.0]
  def up
    Model.all.each do |model|
      if defined?(model.scale_factor) && (model.scale_factor != 100)
        model.update!(notes: [
          model.notes,
          "Scale factor: #{model.scale_factor}%"
        ].compact_blank.join("\n"))
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
