class AddInProgressToProblems < ActiveRecord::Migration[7.1]
  def change
    add_column :problems, :in_progress, :boolean, default: false, null: false
  end
end
