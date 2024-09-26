# frozen_string_literal: true

class GenerateKeypairsForUsers < ActiveRecord::Migration[7.1]
  def up
    Federails::Actor.find_each(&:generate_new_key_pair!)
  end

  def down
  end
end
