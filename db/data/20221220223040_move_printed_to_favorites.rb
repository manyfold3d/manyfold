# frozen_string_literal: true

class MovePrintedToFavorites < ActiveRecord::Migration[7.0]
  def up
    # If there's no "printed" field, there's nothing to move
    return if !ModelFile.has_attribute?(:printed)
    # Move the data over to the first user found
    # If there's more than one, this might be a bad choice,
    # but it's better than nothing
    user = User.first
    ModelFile.where(printed: true).find_each do |file|
      user.favorite(file, scope: :printed)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
