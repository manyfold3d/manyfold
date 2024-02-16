require "string/similarity"

class Scan::AnalyseModelFileJob < ApplicationJob
  queue_as :scan

  def perform(file_id)
    file = ModelFile.find(file_id)
    return if file.nil?
    # Don't run analysis if the file is missing
    # The Problem is raised elsewhere.
    return if !File.exist?(file.pathname)
    # Update stored file metadata if not set
    file.update!(
      digest: file.digest || file.calculate_digest,
      size: file.size || File.size(file.pathname)
    )
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
    best_match = file.model.model_files.presupported.map { |s|
      # Normalize filename
      human = s.name.humanize.downcase
      # Normalize name of this file
      normed = stopword_filter.filter(file.name.humanize.downcase.split)
      # Remove stop words
      human = stopword_filter.filter(human.split)
      # Measure distance from this filename
      [String::Similarity.levenshtein(normed.join(" "), human.join(" ")), s]
    }.max_by { |x| x[0] }
    # Measure distance from this file
    if best_match&.at(0)&.> 0.9
      file.update(presupported_version: best_match[1])
    end
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
