require "string/similarity"

class Analysis::AnalyseModelFileJob < ApplicationJob
  queue_as :low
  unique :until_executed

  def perform(file_id)
    file = ModelFile.find(file_id)
    # Don't run analysis if the file is missing
    # The Problem is raised elsewhere.
    return if !file.exists_on_storage?
    # If the file is modified, or we're lacking metadata
    status[:step] = "jobs.analysis.analyse_model_file.file_statistics" # i18n-tasks-use t('jobs.analysis.analyse_model_file.file_statistics')
    if file.file_last_modified > file.updated_at || file.digest.nil?
      # Store updated file metadata
      file.update!(digest: file.calculate_digest)
      # If the digest has changed, queue up detailed geometric mesh analysis
      file.analyse_geometry_later if file.is_3d_model? && file.digest_previously_changed?
    end
    # Raise problems for empty files
    Problem.create_or_clear file, :empty, (file.size == 0)
    status[:step] = "jobs.analysis.analyse_model_file.matching" # i18n-tasks-use t('jobs.analysis.analyse_model_file.matching')
    # Match supported files
    match_with_supported_file(file)
    status[:step] = "jobs.analysis.analyse_model_file.detect_ineffiency" # i18n-tasks-use t('jobs.analysis.analyse_model_file.detect_ineffiency')
    # Detect inefficient file formats
    message = inefficiency_problem(file)
    Problem.create_or_clear(
      file,
      :inefficient,
      !message.nil?,
      note: message
    )
    status[:step] = "jobs.analysis.analyse_model_file.detect_duplicates" # i18n-tasks-use t('jobs.analysis.analyse_model_file.detect_duplicates')
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
    matches = file.model.model_files.presupported.select { |x| x.extension.downcase == file.extension.downcase }.map { |s|
      # Normalize filename
      human = s.name.humanize.downcase
      # Normalize name of this file
      normed = stopword_filter.filter(file.name.humanize.downcase.split)
      # Remove stop words
      human = stopword_filter.filter(human.split)
      # Measure distance from this filename
      d = String::Similarity.cosine(normed.join(" "), human.join(" "))
      [d, s]
    }.select { |it| it[0] > 0.95 }
    best = case matches.length
    when 0
      nil
    when 1
      matches.first[1]
    else
      same_format = matches.select { |it| it[1].mime_type === file.mime_type }
      matches = same_format unless same_format.empty?
      matches.max_by { |it| it[0] }[1]
    end
    file.update(presupported_version: best)
  end

  def inefficiency_problem(file)
    return "ASCII STL" if (file.extension === "stl") && (file.head(6) === "solid ")
    return "Wavefront OBJ" if file.extension === "obj"
    return "ASCII PLY" if (file.extension === "ply") && (file.head(16) === "ply\rformat ascii")
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
