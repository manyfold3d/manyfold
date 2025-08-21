# frozen_string_literal: true

class MakeNamesUnique < ActiveRecord::Migration[7.0]
  def up
    attributes = [:name, :slug]
    [Creator, Collection].each do |klass|
      attributes.each do |attr|
        klass.all.group_by { |it| it.send(attr)&.downcase }.each_pair do |n, items|
          if items.count > 1
            items.slice(1..-1).each do |c|
              c.name = "#{c.name} #{SecureRandom.hex(4)}"
              c.save!
            end
          end
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
