# frozen_string_literal: true

class MakePublicIDsLowercase < ActiveRecord::Migration[7.2]
  def up
    [
      Collection,
      Comment,
      Creator,
      Library,
      ModelFile,
      Model,
      Problem,
      User
    ].each do |it|
      it.update_all("public_id = lower(public_id)") # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def down
  end
end
