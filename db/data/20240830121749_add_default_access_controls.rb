# frozen_string_literal: true

class AddDefaultAccessControls < ActiveRecord::Migration[7.1]
  def up
    [Creator, Collection, Model].each do |klass|
      klass.find_each(&:assign_default_permissions)
    end
  end

  def down
  end
end
