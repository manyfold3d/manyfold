# This migration comes from federails (originally 20240731145400)
class ChangeActorEntityRelToPolymorphic < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :federails_actors, column: :user_id, to_table: Federails::Configuration.user_table
    remove_index :federails_actors, :user_id, unique: true
    change_table :federails_actors do |t|
      t.rename :user_id, :entity_id
      t.string :entity_type, null: true, default: Federails::Configuration.user_class&.demodulize
      t.index [:entity_type, :entity_id], name: "index_federails_actors_on_entity", unique: true
    end
  end
end
