class Upgrade::BackfillImageDerivatives < Upgrade::BackfillDerivativesBase
  queue_as :low

  def mime_types
    SupportedMimeTypes.image_types.without(Mime[:svg])
  end

  def derivative
    "preview"
  end
end
