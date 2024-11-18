# frozen_string_literal: true

class ClearStuckProblems < ActiveRecord::Migration[7.2]
  def up
    Problem.update_all(in_progress: false) # rubocop:disable Rails/SkipsModelValidations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
