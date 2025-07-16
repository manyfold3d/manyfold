class AddIndexOnLinkUrl < ActiveRecord::Migration[8.0]
  def change
    change_table :links do |t|
      t.index :url
    end
  end
end
