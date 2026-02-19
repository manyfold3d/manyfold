# frozen_string_literal: true

class Upgrade::FixMimeTypes < Upgrade::FileTypeIterationJob
  def mime_types
    [
      "text/plain",
      "application/octet-stream",
      "application/zip"
    ]
  end

  def apply(modelfile)
    modelfile.refresh_metadata!
  end
end
