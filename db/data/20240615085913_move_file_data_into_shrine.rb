# frozen_string_literal: true

class MoveFileDataIntoShrine < ActiveRecord::Migration[7.0]
  def up
    ModelFile.find_each { |x| x.attach_existing_file!(refresh: false) }
  end

  def down
  end
end
