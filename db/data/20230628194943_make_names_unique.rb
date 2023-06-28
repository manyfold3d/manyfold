# frozen_string_literal: true

class MakeNamesUnique < ActiveRecord::Migration[7.0]
  def up
    [Creator, Collection].each do |klass|
      klass.all.group_by { |x| x.name.downcase }.each_pair do |name, items|
        if items.count > 1
          items.slice(1..-1).each do |c|
            c.name = "#{c.name} #{SecureRandom.hex(4)}"
            c.save!
          end
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
