# frozen_string_literal: true

class DeduplicateRoles < ActiveRecord::Migration[7.1]
  def up
    Role.merge_duplicates!
  end

  def down
  end
end
