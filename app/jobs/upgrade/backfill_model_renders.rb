class Upgrade::BackfillModelRenders < Upgrade::BackfillDerivativesBase
  queue_as :performance

  def mime_types
    SupportedMimeTypes.renderable_types
  end

  def derivative
    "render"
  end

  def apply(modelfile)
    status[:step] = "jobs.upgrade.backfill_model_renders.rendering"
    status[:message_variables] = {
      filename: modelfile.filename,
      model_name: modelfile.model.name
    }
    super
  end
end
