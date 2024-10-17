# frozen_string_literal: true

class RemoveDestinationExistsProblems < ActiveRecord::Migration[7.0]
  def up
    # Clean up deprecated problems
    Problem.unscoped.where(category: :destination_exists).destroy_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
