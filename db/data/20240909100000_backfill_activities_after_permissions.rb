# frozen_string_literal: true

class BackfillActivitiesAfterPermissions < ActiveRecord::Migration[7.1]
  def up
    Model.unscoped.limit(20).order(created_at: :desc).each do |model|
      model.send :post_creation_activity if model.actor&.activities&.empty?
    end
  end

  def down
  end
end
