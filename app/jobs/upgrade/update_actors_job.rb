# frozen_string_literal: true

require "federails/maintenance/actors_updater"
class Upgrade::UpdateActorsJob < ApplicationJob
  queue_as :upgrade
  unique :until_executed

  def perform
    if SiteSettings.federation_enabled?
      # Fix incorrectly-flagged local actors
      Federails::Actor.where(local: true)
        .where.not(server: [PublicUrl.hostname, nil])
        .update_all(local: false) # rubocop:disable Rails/SkipsModelValidations
      # Update remove actor data
      Federails::Maintenance::ActorsUpdater.run
    end
  end
end
