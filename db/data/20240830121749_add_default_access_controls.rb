# frozen_string_literal: true

class AddDefaultAccessControls < ActiveRecord::Migration[7.1]
  def up
    [Creator, Collection, Model].each do |klass|
      klass.find_each(&:set_owner)
      klass.find_each(&:set_permissions_from_preset)
    end
  end

  def down
  end
end
