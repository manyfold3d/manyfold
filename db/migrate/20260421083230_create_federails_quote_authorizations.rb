class CreateFederailsQuoteAuthorizations < ActiveRecord::Migration[8.0]
  def change
    create_table :federails_quote_authorizations do |t|
      t.string :uuid, null: false
      t.string :state, default: nil
      t.string :interacting_object_url, null: false
      t.belongs_to :interaction_target, polymorphic: true, null: false
      t.belongs_to :federails_actor, null: false, foreign_key: true
      t.belongs_to :quoting_actor, null: false, foreign_key: {to_table: "federails_actors"}
      t.string :quote_request_url, null: false
      t.timestamps
    end
  end
end
