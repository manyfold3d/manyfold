class RemoveUnneededIndexes < ActiveRecord::Migration[7.1]
  def change
    # Remove duplicate indexes as detected by PgHero
    remove_index :favorites, name: "index_favorites_on_favoritable", column: [:favoritable_type, :favoritable_id]
    remove_index :federails_followings, name: "index_federails_followings_on_actor_id", column: :actor_id
    remove_index :roles, name: "index_roles_on_name", column: :name
    remove_index :taggings, name: "index_taggings_on_tag_id", column: :tag_id
    remove_index :taggings, name: "index_taggings_on_taggable_id", column: :taggable_id
    remove_index :taggings, name: "index_taggings_on_tagger_id", column: :tagger_id
    remove_index :users_roles, name: "index_users_roles_on_user_id", column: :user_id
  end
end
