class Scan::ModelFile::ParseMetadataJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  def perform(file_id)
    file = ModelFile.find(file_id)
    # Refresh shrine metadata
    file.attachment_attacher.refresh_metadata!
    # Get metadata for specific types
    params = if file.is_image?
      image_metadata(file)
    elsif file.is_3d_model?
      model_metadata(file)
    end
    # Store updated data
    file.update!(params.compact) if params
    # Queue up deeper analysis job
    file.analyse_later
  end

  def image_metadata(file)
    {
      previewable: true
    }
  end

  def model_metadata(file)
    {
      presupported: presupported?(file)
    }
  end

  def presupported?(file)
    elements = file.path_within_library.split(/[[:punct:]]|[[:space:]]/).map(&:downcase)
    elements.any? { |it| ModelFile::SUPPORT_KEYWORDS.include?(it) }
  end
end
