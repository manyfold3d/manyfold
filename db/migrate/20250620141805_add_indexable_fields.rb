class AddIndexableFields < ActiveRecord::Migration[8.0]
  def change
    [:models, :creators, :collections].each do |table|
      change_table table do |t|
        t.integer :indexable, null: true, default: nil
        t.integer :ai_indexable, null: true, default: nil
      end
    end
  end
end
