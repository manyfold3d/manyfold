class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments do |t|
      t.string :public_id, null: false, index: {unique: true}
      t.references :commenter, polymorphic: true, null: false
      t.references :commentable, polymorphic: true, null: false
      t.text :comment

      t.timestamps
    end
  end
end
