# frozen_string_literal: true

class CreatePublicIDsForUsers < ActiveRecord::Migration[7.1]
  def up
    User.find_each do |u|
      # validation and save will generate public IDs
      u.save if u.valid?
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
