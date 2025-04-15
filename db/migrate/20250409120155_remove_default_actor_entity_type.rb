class RemoveDefaultActorEntityType < ActiveRecord::Migration[7.2]
  def up
    change_column_default :federails_actors, :entity_type, nil
  end

  def down
  end
end
