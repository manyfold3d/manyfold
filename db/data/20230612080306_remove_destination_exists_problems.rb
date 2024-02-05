# frozen_string_literal: true

class RemoveDestinationExistsProblems < ActiveRecord::Migration[7.0]
  def up
    # Clean up deprecated problems
    Problem.where(category: :destination_exists).destroy_all
  rescue # To avoid crashes when the ignored field in Problem's default scope isn't available yet
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
