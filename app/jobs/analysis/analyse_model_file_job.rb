require "string/similarity"

class Analysis::AnalyseModelFileJob < ApplicationJob
  queue_as :analysis

  def perform(file_id)
    begin
      file = ModelFile.find(file_id)
    rescue ActiveRecord::RecordNotFound
      logger.warn "Analysis::AnalyseModelFileJob aborted, invalid ModelFile ID #{file_id}"
      return
    end
    # Don't run analysis if the file is missing
    # The Problem is raised elsewhere.
    return if !File.exist?(file.pathname)
    # If the file is modified, or we're lacking metadata
    if File.mtime(file.pathname) > file.updated_at || file.digest.nil? || file.size.nil?
      file.digest = file.calculate_digest
      file.size = File.size(file.pathname)
      # If the digest has changed, queue up detailed geometric mesh analysis
      Analysis::GeometricAnalysisJob.perform_later(file_id) if file.digest_changed?
      # Store updated file metadata
      file.save!
    end
    # Match supported files
    match_with_supported_file(file)
    # Detect inefficient file formats
    message = inefficiency_problem(file)
    Problem.create_or_clear(
      file,
      :inefficient,
      !message.nil?,
      note: message
    )
    # Detect duplicates
    Problem.create_or_clear(
      file,
      :duplicate,
      file.duplicate?
    )
  end

  def match_with_supported_file(file)
    # If this is a supported file or already matched, don't do anything
    return if file.presupported || file.presupported_version
    # Otherwise, find presupported files in the same model
    # Build list of files with normalised names
    matches = file.model.model_files.presupported.map { |s|
      # Normalize filename
      human = s.name.humanize.downcase
      # Normalize name of this file
      normed = stopword_filter.filter(file.name.humanize.downcase.split)
      # Remove stop words
      human = stopword_filter.filter(human.split)
      # Measure distance from this filename
      d = String::Similarity.cosine(normed.join(" "), human.join(" "))
      [d, s]
    }.select { |x| x[0] > 0.95 }
    best = case matches.length
    when 0
      nil
    when 1
      matches.first[1]
    else
      same_format = matches.select { |x| x[1].mime_type === file.mime_type }
      matches = same_format unless same_format.empty?
      matches.max_by { |x| x[0] }[1]
    end
    file.update(presupported_version: best)
  end

  def inefficiency_problem(file)
    return "ASCII STL" if (file.extension === "stl") && (File.read(file.pathname, 6) === "solid ")
    return "Wavefront OBJ" if file.extension === "obj"
    return "ASCII PLY" if (file.extension === "ply") && (File.read(file.pathname, 16) === "ply\rformat ascii")
    nil
  end

  private

  def stopword_filter
    # Create stopwords filter
    @@filter ||= Stopwords::Snowball::Filter.new(
      SiteSettings.model_tags_stop_words_locale,
      SiteSettings.model_tags_custom_stop_words + ModelFile::SUPPORT_KEYWORDS
    )
  end
end
