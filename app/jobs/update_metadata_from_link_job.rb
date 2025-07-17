class UpdateMetadataFromLinkJob < ApplicationJob
  queue_as :low
  unique :until_executed

  def perform(link:, organize: false)
    return unless (data = link.deserializer&.deserialize)
    linkable = link.linkable
    # Preserve existing tags
    data[:tag_list]&.concat(linkable.tag_list)&.uniq
    # Update object
    linkable.update! data.except(:file_urls, :preview_filename)
    # Import files for models
    if linkable.is_a? Model
      # Organize model if set
      linkable.organize! if organize
      # Download files
      data.dig(:file_urls)&.each do |it|
        linkable.add_file_from_url(url: it[:url], filename: it[:filename])
      rescue ActiveRecord::RecordInvalid
        Rails.logger.info("Couldn't add file #{it[:url]} to model #{linkable.to_param}")
      end
      # Select preview file
      data[:preview_file] = linkable.model_files.find_by(filename: data[:preview_filename]) if data[:preview_filename].present?
    end
  end
end
