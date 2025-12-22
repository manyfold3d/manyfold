class Upgrade::FixStaleAttachmentDataJob < ApplicationJob
  include JobIteration::Iteration

  queue_as :low
  unique :until_executed

  def scope
    where_clause = case DatabaseDetector.server
    when :postgresql
      "json_extract_path_text(attachment_data, 'storage') = 'cache'"
    when :mysql
      "json_value(attachment_data, '$.storage') = 'cache'"
    when :sqlite
      "json_extract(attachment_data, '$.storage') = 'cache'"
    else
      raise NotImplementedError.new("Unknown database adapter #{ApplicationRecord.connection.adapter_name}")
    end
    ModelFile.unscoped.where(where_clause)
  end

  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(scope, cursor: cursor)
  end

  def each_iteration(modelfile)
    modelfile.attachment_data.store("id", modelfile.path_within_library)
    modelfile.attachment_data.store("storage", modelfile.model.library.storage_key.to_s)
    modelfile.save!
  end
end
