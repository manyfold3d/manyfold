class UpdateMetadataFromLinkJob < ApplicationJob
  queue_as :low
  unique :until_executed

  def perform(link:)
    if (data = link.deserializer&.deserialize)
      link.linkable.update!(data)
    end
  end
end
