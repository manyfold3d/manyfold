# frozen_string_literal: true

class Upgrade::FixNilFileSizeValues < ApplicationJob
  queue_as :upgrade

  def perform
    batch_size = 100

    # Update all Model Files where size is nil
    ModelFile.where(size: nil).find_each(batch_size: batch_size) do |modelfile|
      modelfile.update(size: modelfile.attachment_data["metadata"]["size"]) if modelfile.attachment_data?
    end
  end
end
