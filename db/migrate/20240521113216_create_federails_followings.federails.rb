# This migration comes from federails (originally 20200712143127)
class CreateFederailsFollowings < ActiveRecord::Migration[7.0]
  def change
    create_table :federails_followings do |t|
      t.references :actor, null: false, foreign_key: {to_table: :federails_actors}
      t.references :target_actor, null: false, foreign_key: {to_table: :federails_actors}
      t.integer :status, default: 0
      t.string :federated_url

      t.timestamps

      t.index [:actor_id, :target_actor_id], unique: true
    end
  end
end
