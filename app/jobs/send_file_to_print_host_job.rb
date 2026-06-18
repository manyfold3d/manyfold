class SendFileToPrintHostJob < ApplicationJob
  queue_as :low
  unique :until_executed

  def perform(print_host:, file:)
    service = print_host.service
    service.upload(file: file, start_print: true)
  end
end
