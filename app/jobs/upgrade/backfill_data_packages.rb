# frozen_string_literal: true

class Upgrade::BackfillDataPackages < ApplicationJob
  queue_as :upgrade

  def perform
    # Find models that don't have a datapackage and enqueue their generation
    Model.where.not(
      id: ModelFile.including_special.where(filename: "datapackage.json").select(:model_id)
    ).pluck(:id).each do |id|
      UpdateDatapackageJob.perform_later(id)
    end
  end
end
