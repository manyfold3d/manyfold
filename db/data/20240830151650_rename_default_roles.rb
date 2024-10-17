# frozen_string_literal: true

class RenameDefaultRoles < ActiveRecord::Migration[7.1]
  def up
    Role.find_by(name: :editor)&.update!(name: :moderator) unless Role.find_by(name: :moderator)
    Role.find_by(name: :viewer)&.update!(name: :member) unless Role.find_by(name: :member)
  end

  def down
    Role.find_by(name: :moderator)&.update!(name: :editor)
    Role.find_by(name: :member)&.update!(name: :viewer)
  end
end
