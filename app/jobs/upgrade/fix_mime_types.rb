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
    ApplicationRecord.no_touching do
      modelfile.attachment_attacher.add_metadata(
        "mime_type" => ApplicationUploader.determine_mime_type(modelfile.attachment)
      )
      modelfile.save(touch: false, validate: false)
    end
  end
end
