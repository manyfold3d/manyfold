class Upgrade::BackfillModelRenders < Upgrade::BackfillDerivativesBase
  queue_as :performance

  def mime_types
    SupportedMimeTypes.renderable
  end

  def derivative
    "render"
  end
end
