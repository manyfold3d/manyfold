class UpdateMetadataFromLinkJob < ApplicationJob
  queue_as :low
  unique :until_executed

  def perform(link:)
    # Read from API
    return unless (data = link.deserializer&.deserialize)
    # Handle model-specific info
    linkable = link.linkable
    if linkable.is_a? Model
      # Download files
      data.delete(:file_urls)&.each { |it| linkable.add_file_from_url(it) }
      # Select preview file
      data[:preview_file] = linkable.model_files.find_by(filename: data.delete(:preview_filename)) if data[:preview_filename].present?
    end
    # Update object
    linkable.update! data
  end
end
