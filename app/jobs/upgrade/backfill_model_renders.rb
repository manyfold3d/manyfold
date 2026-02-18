class Upgrade::BackfillModelRenders < Upgrade::BackfillDerivativesBase
  queue_as :performance

  def mime_types
    SupportedMimeTypes.renderable_types
  end

  def derivative
    "render"
  end
end
