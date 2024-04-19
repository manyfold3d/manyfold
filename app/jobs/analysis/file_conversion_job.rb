require "string/similarity"

class UnsupportedFormatError < StandardError
end

class NonManifoldError < StandardError
end

class Analysis::FileConversionJob < ApplicationJob
  queue_as :analysis

  def perform(file_id, output_format)
    # Can we output this format?
    raise UnsupportedFormatError unless SupportedMimeTypes.can_export?(output_format)
    # Get model
    file = ModelFile.find(file_id)
    exporter = nil
    extension = nil
    status[:step] = "jobs.analysis.file_conversion.loading_mesh"
    case output_format
    when :threemf
      raise NonManifoldError.new if !file.mesh.manifold?
      extension = "3mf"
      exporter = Mittsu::ThreeMFExporter.new
    end
    if exporter
      status[:step] = "jobs.analysis.file_conversion.exporting"
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
