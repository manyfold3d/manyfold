class Upgrade::BackfillImageDerivatives < Upgrade::BackfillDerivativesBase
  queue_as :low

  def mime_types
    SupportedMimeTypes.image_types
  end

  def derivative
    "preview"
  end
end
