# This migration comes from federails (originally 20200712133150)
class CreateFederailsActors < ActiveRecord::Migration[7.0]
  def change
    create_table :federails_actors do |t|
      t.string :name
      t.string :federated_url
      t.string :username
      t.string :server
      t.string :inbox_url
      t.string :outbox_url
      t.string :followers_url
      t.string :followings_url
      t.string :profile_url

      t.references :user, null: true, foreign_key: {to_table: Federails.configuration.user_table}

      t.timestamps
      t.index :federated_url, unique: true
    end
    if foreign_key_exists?(:federails_actors, :users)
      remove_foreign_key :federails_actors, :users
    end
    remove_index :federails_actors, :user_id
    add_index :federails_actors, :user_id, unique: true
    add_foreign_key :federails_actors, :users
  end
end
