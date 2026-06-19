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

    # Can we convert this format?
    raise UnsupportedFormatError unless file.convertable?(to: output_format)
    extension = Mime::EXTENSION_LOOKUP.select { |k, v| v.symbol == output_format }.keys.last

    status[:step] = "jobs.analysis.file_conversion.loading_mesh" # i18n-tasks-use t('jobs.analysis.file_conversion.loading_mesh')
    scene = file.scene

    # Manifold check for 3MF files
    # raise NonManifoldError.new if output_format == :threemf && !file.manifold?

    status[:step] = "jobs.analysis.file_conversion.exporting" # i18n-tasks-use t('jobs.analysis.file_conversion.exporting')
    new_file = ModelFile.new(
      model: file.model,
      filename: Pathname.new(file.filename).sub_ext(".#{extension}"),
      presupported: file.presupported,
      y_up: file.y_up,
      previewable: file.previewable,
      caption: file.caption,
      notes: file.notes
    )
    dedup = 0
    while new_file.exists_on_storage?
      dedup += 1
      new_file.filename = Pathname.new(file.filename).sub_ext("-#{dedup}.#{extension}")
    end
    # Save the new file into the Shrine cache, and attach
    Tempfile.create("", ModelFileUploader.find_storage(:cache).directory) do |outfile|
      scene.export(extension, outfile.path)
      new_file.attachment = ModelFileUploader.uploaded_file(
        storage: :cache,
        id: File.basename(outfile.path),
        metadata: {
          filename: new_file.filename,
          size: File.size(outfile.path)
        }
      )
    end
    # Set relationship between new file and old
    new_file.relationships << Relationship.new(subject: new_file, objekt: file, predicate: "alternative_format_of")
    # Store record in database
    new_file.save
    # Queue up file scan
    new_file.analyse_later
    # Update the UI
    file.broadcast_refresh
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
      file.problems.where(category: :inefficient, in_progress: true).find_each do
        it.update(in_progress: false)
      end
    end
  end
end
