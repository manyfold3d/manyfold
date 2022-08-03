# frozen_string_literal: true

class MovePrintedToFavorites < ActiveRecord::Migration[7.0]
  def up
    # If there's more than one user, we can't really do anything so abort
    if User.count != 1
      raise ActiveRecord::ConfigurationError
    else
      user = User.first
      ModelFile.where(printed: true).each do |file|
        user.favorite(file, scope: :printed)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
