class Activity::WebSubPublishJob < ApplicationJob
  queue_as :activity

  def perform(topic)
    return unless SiteSettings.web_sub_hub

    Faraday.default_connection.post(
      SiteSettings.web_sub_hub,
      {
        "hub.mode" => "publish",
        "hub.topic" => topic
      }
    )
  end
end
