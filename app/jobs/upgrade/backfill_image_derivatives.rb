class Upgrade::BackfillImageDerivatives < Upgrade::BackfillDerivativesBase
  queue_as :low

  def mime_types
    SupportedMimeTypes.image_types.without(Mime[:svg])
  end

  def derivative
    "preview"
  end

  def apply(modelfile)
    status[:step] = "jobs.upgrade.backfill_image_derivatives.processing" # i18n-tasks-use t('jobs.upgrade.backfill_image_derivatives.processing')
    status[:message_variables] = {
      filename: modelfile.filename,
      model_name: modelfile.model.name
    }
    super
  end
end
