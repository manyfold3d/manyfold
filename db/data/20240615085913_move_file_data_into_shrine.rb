# frozen_string_literal: true

class MoveFileDataIntoShrine < ActiveRecord::Migration[7.0]
  def up
    ModelFile.find_each(&:attach_existing_file!)
  end

  def down
  end
end
