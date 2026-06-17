class SendFileToPrintHostJob < ApplicationJob
  queue_as :low
  unique :until_executed

  def perform(print_host:, file:)
    service = print_host.service
    # Check print host is OK before sending, otherwise raise an ArgumentError to try again later
    raise PrintHost::NotReady unless service.ok?
    service.upload(file: file, start_print: true)
  end
end
