# frozen_string_literal: true

class Upgrade::BackfillDataPackages < ApplicationJob
  queue_as :upgrade
  unique :until_executed

  def perform
    # Find models that don't have a datapackage and enqueue their generation
    Model.where.not(
      id: ModelFile.where(filename: "datapackage.json").select(:model_id)
    ).each do |model|
      model.write_datapackage_later
    end
  end
end
