class ChangeIndexableFromIntegerToString < ActiveRecord::Migration[8.0]
  def up
    [:models, :creators, :collections].each do |table|
      change_column table, :indexable, :string
      change_column table, :ai_indexable, :string
    end
  end

  def down
    [:models, :creators, :collections].each do |table|
      change_column table, :indexable, :integer
      change_column table, :ai_indexable, :integer
    end
  end
end
