class AddPreviewPartToModel < ActiveRecord::Migration[6.1]
  def change
    add_reference :models, :preview_part, null: true, foreign_key: {to_table: :parts}
  end
end
