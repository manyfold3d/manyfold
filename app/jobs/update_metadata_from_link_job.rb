class UpdateMetadataFromLinkJob < ApplicationJob
  queue_as :low
  unique :until_executed

  def perform(link:, organize: false)
    return unless (data = link.deserializer&.deserialize)
    linkable = link.linkable
    # Preserve existing tags
    data[:tag_list]&.concat(linkable.tag_list)&.uniq
    # Match to existing creator
    if data[:creator_attributes]
      creator = Creator.find_by(slug: data.dig(:creator_attributes, :slug))
      if creator
        data.delete :creator_attributes
        data[:creator_id] = creator.id
      end
    end
    # Update object
    linkable.update! data.except(:file_urls, :preview_filename)
    # Import files for models
    if linkable.is_a? Model
      linkable.organize! if organize
      import_files(data, linkable)
    end
  end

  def import_files(data, model)
    data.dig(:file_urls)&.each do |it|
      model.add_file_from_url(url: it[:url], filename: it[:filename])
    rescue ActiveRecord::RecordInvalid
      Rails.logger.info("Couldn't add file #{it[:url]} to model #{model.to_param}")
    end
    # Select preview file
    model.update!(preview_file: model.model_files.find_by(filename: data[:preview_filename])) if data[:preview_filename].present?
  end
end
