# frozen_string_literal: true

class RenameDefaultRoles < ActiveRecord::Migration[7.1]
  def up
    Role.find_by(name: :editor).update!(name: :moderator)
  end

  def down
    Role.find_by(name: :moderator).update!(name: :editor)
  end
end
