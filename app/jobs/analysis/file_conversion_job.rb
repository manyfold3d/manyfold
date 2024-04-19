require "string/similarity"

class Analysis::FileConversionJob < ApplicationJob
  queue_as :analysis

  def perform(file_id, output_format)
    # Can we output this format?
    unless SupportedMimeTypes.can_export?(output_format)
      logger.warn "Analysis::FileConversionJob aborted, format #{output_format} is not supported"
      return
    end
    # Get model
    file = ModelFile.find(file_id)
    exporter = nil
    extension = nil
    case output_format
    when :threemf
      if file.mesh.manifold?
        extension = "3mf"
        exporter = Mittsu::ThreeMFExporter.new
      else
        logger.warn "Analysis::FileConversionJob aborted: can't save non-manifold mesh to 3MF for ModelFile ID #{file_id}"
        return
      end
    else
      logger.error "Analysis::FileConversionJob error: unhandled output format #{output_format}"
    end
    if exporter
      new_file = ModelFile.new(
        model: file.model,
        filename: file.filename.gsub(".#{file.extension}", ".#{extension}")
      )
      dedup = 0
      while File.exist?(new_file.pathname)
        dedup += 1
        new_file.filename = file.filename.gsub(".#{file.extension}", "-#{dedup}.#{extension}")
      end
      # Save the actual file in new format
      exporter.export(file.mesh, new_file.pathname)
      # Store record in database
      new_file.save
      # Queue up file scan
      Analysis::AnalyseModelFileJob.perform_later(new_file.id)
    end
  end
end
