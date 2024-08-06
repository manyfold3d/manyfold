# frozen_string_literal: true

class CreateFederailsActors < ActiveRecord::Migration[7.1]
  def up
    User.find_each do |user|
      user.create_actor_if_missing
    end
  end

  def down
  end
end
