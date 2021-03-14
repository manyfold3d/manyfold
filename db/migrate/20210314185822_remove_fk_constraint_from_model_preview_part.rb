class RemoveFkConstraintFromModelPreviewPart < ActiveRecord::Migration[6.1]
  def change
    remove_foreign_key :models, :parts, column: :preview_part_id
  end
end
