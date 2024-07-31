# frozen_string_literal: true

class CreateFederailsActors < ActiveRecord::Migration[7.1]
  def up
    User.find_each do |user|
      user.send(:create_actor) if user.actor.nil?
    end
  end

  def down
  end
end
