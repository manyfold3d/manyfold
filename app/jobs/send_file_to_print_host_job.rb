# frozen_string_literal: true

# Uploads a sliced CTB/JXS ModelFile to an SDCP PrintHost and starts the job.
class SendFileToPrintHostJob < ApplicationJob
  queue_as :default

  def perform(print_host, model_file)
    raise ArgumentError, "print_host required" unless print_host
    raise ArgumentError, "model_file required" unless model_file

    filename = File.basename(model_file.filename.to_s)
    service = print_host.service

    model_file.attachment.open do |io|
      service.upload(io: io, filename: filename, start: true)
    end
  end
end
