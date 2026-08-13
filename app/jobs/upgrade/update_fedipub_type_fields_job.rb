# frozen_string_literal: true

class Upgrade::UpdateFedipubTypeFieldsJob < ApplicationJob
  def perform
    [
      [Comment, :commenter_type]
    ].each do |table, field|
      table.where(field => "Federails::Actor").update_all(field => "Fedipub::Actor")
    end
  end
end
