# This migration comes from fedipub (originally 20260922155524)
class CreateFedipubApprovalStamps < ActiveRecord::Migration[7.2]
  def change
    create_table :fedipub_approval_stamps do |t|
      t.string :uuid, null: false
      t.string :approval_type, null: false
      t.string :interacting_object_url, null: false
      t.belongs_to :interaction_target, polymorphic: true, null: false
      t.belongs_to :fedipub_actor, null: false, foreign_key: true
      t.timestamps
    end
  end
end
