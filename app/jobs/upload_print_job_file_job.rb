# frozen_string_literal: true

# Uploads a PrintJob's ModelFile to the host without starting the print (INIT-008/SPEC-003).
class UploadPrintJobFileJob < ApplicationJob
  queue_as :default

  def perform(print_job_id)
    print_job = PrintJob.find(print_job_id)
    model_file = print_job.model_file
    raise ArgumentError, "print_job #{print_job_id} has no model_file" unless model_file

    filename = File.basename(model_file.filename.to_s)
    service = Print::JobService.new(print_host: print_job.print_host, actor: nil)

    model_file.attachment.open do |io|
      service.upload!(print_job, io: io, filename: filename, enqueue: false)
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn("UploadPrintJobFileJob: #{e.message}")
  end
end
