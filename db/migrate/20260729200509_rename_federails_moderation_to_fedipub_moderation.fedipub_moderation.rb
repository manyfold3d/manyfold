# This migration comes from fedipub_moderation (originally 20260729204941)
class RenameFederailsModerationToFedipubModeration < ActiveRecord::Migration[7.0]
  def change
    rename_column :federails_moderation_reports, :federails_actor_id, :fedipub_actor_id
    rename_index :federails_moderation_reports, "index_federails_moderation_reports_on_object", "index_fedipub_moderation_reports_on_object"
    rename_table :federails_moderation_reports, :fedipub_moderation_reports
    rename_table :federails_moderation_domain_blocks, :fedipub_moderation_domain_blocks
  end
end
