# This migration comes from federails_moderation (originally 20241127105043)
class CreateFederailsModerationReports < ActiveRecord::Migration[7.0]
  def change
    create_table :federails_moderation_reports do |t|
      t.string :federated_url
      t.references :federails_actor, foreign_key: true
      t.string :content
      t.references :object, polymorphic: true
      t.datetime :resolved_at
      t.string :resolution
      t.timestamps
    end
  end
end
