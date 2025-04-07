# frozen_string_literal: true

class Upgrade::UpdateActorsJob < ApplicationJob
  queue_as :upgrade
  unique :until_executed

  def perform
    Federails::Maintenance::ActorsUpdater.run
  end
end
