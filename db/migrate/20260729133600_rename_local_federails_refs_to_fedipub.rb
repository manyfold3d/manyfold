class RenameLocalFederailsRefsToFedipub < ActiveRecord::Migration[8.0]
  def change
    rename_column :comments, :federails_actor_id, :fedipub_actor_id
    remove_foreign_key :federails_quote_authorizations, :fedipub_actors, column: :quoting_actor_id
    rename_column :federails_quote_authorizations, :federails_actor_id, :fedipub_actor_id
    rename_table :federails_quote_authorizations, :fedipub_quote_authorizations
    add_foreign_key :fedipub_quote_authorizations, :fedipub_actors, column: :quoting_actor_id
  end
end
