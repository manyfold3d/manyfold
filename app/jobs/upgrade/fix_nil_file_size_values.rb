# frozen_string_literal: true

class Upgrade::FixNilFileSizeValues < ApplicationJob
  include JobIteration::Iteration
  unique :until_executed

  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(ModelFile.unscoped.where(size: nil), cursor: cursor)
  end

  def each_iteration(modelfile)
    modelfile.update(size: modelfile.attachment_data["metadata"]["size"]) if modelfile.attachment_data?
  end
end
