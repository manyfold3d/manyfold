# frozen_string_literal: true

require "federails/maintenance/actors_updater"
class Upgrade::UpdateActorsJob < ApplicationJob
  queue_as :upgrade
  unique :until_executed

  def perform
    Federails::Maintenance::ActorsUpdater.run
  end
end
