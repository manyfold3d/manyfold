class AddIgnoredToProblems < ActiveRecord::Migration[7.0]
  def change
    add_column :problems, :ignored, :boolean, default: false, null: false
  end
end
