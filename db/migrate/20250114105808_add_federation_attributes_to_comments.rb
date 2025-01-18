class AddFederationAttributesToComments < ActiveRecord::Migration[7.2]
  def change
    # Commenter is now optional
    change_column_null :comments, :commenter_id, true
    change_column_null :comments, :commenter_type, true
    # New columns for federation work
    add_column :comments, :federated_url, :string, null: true, default: nil
    add_reference :comments, :federails_actor, null: true, foreign_key: true
  end
end
