require "string/similarity"

class UnsupportedFormatError < StandardError
end

class NonManifoldError < StandardError
end

class Analysis::FileConversionJob < ApplicationJob
  queue_as :performance
  sidekiq_options retry: false
  unique :until_executed

  def perform(file_id, output_format)
    # Get model
    file = ModelFile.find(file_id)
    # Can we output this format?
    raise UnsupportedFormatError unless SupportedMimeTypes.can_export?(output_format) || !file.loadable?
    extension = nil
    status[:step] = "jobs.analysis.file_conversion.loading_mesh" # i18n-tasks-use t('jobs.analysis.file_conversion.loading_mesh')
    case output_format
    when :threemf
      raise NonManifoldError.new if !file.manifold?
      extension = "3mf"
    end
    if extension
      status[:step] = "jobs.analysis.file_conversion.exporting" # i18n-tasks-use t('jobs.analysis.file_conversion.exporting')
      new_file = ModelFile.new(
        model: file.model,
        filename: file.filename.gsub(".#{file.extension}", ".#{extension}")
      )
      dedup = 0
      while new_file.exists_on_storage?
        dedup += 1
        new_file.filename = file.filename.gsub(".#{file.extension}", "-#{dedup}.#{extension}")
      end
      # Save the new file into the Shrine cache, and attach
      Tempfile.create("", ModelFileUploader.find_storage(:cache).directory) do |outfile|
        file.scene.export(extension, outfile.path)
        new_file.attachment = ModelFileUploader.uploaded_file(
          storage: :cache,
          id: File.basename(outfile.path),
          metadata: {
            filename: new_file.filename,
            size: File.size(outfile.path)
          }
        )
      end
      # Store record in database
      new_file.save
      # Queue up file scan
      new_file.analyse_later
    end
  rescue NonManifoldError
    # Log non-manifold error as a problem, and absorb error so we don't retry
    Problem.create_or_clear(
      file,
      :non_manifold,
      true
    )
  ensure
    if file
      # Mark inefficient problem resolution as no longer in progress, if it's set
      file.problems.where(category: :inefficient, in_progress: true).find_each do |it|
        it.update(in_progress: false)
      end
    end
  end
end
