# frozen_string_literal: true

class ConvertAdminFlagToRole < ActiveRecord::Migration[7.0]
  def up
    User.where(admin: true).find_each { |u| u.add_role :administrator }
  rescue ActiveRecord::StatementInvalid
  end

  def down
    User.with_role(:administrator).find_each { |u| u.update!(admin: true) }
  end
end
