# frozen_string_literal: true

class CreateMoreFederailsActors < ActiveRecord::Migration[7.1]
  def up
    entity_classes = [User, Model, Creator, Collection]
    entity_classes.each do |entity_class|
      puts "Creating actors for #{entity_class.name}" # rubocop:todo Rails/Output
      entity_class.find_each do |entity|
        putc "." # rubocop:todo Rails/Output
        entity.create_actor_if_missing
      end
      puts # rubocop:todo Rails/Output
    end
  end

  def down
  end
end
