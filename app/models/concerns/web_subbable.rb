module WebSubbable
  extend ActiveSupport::Concern

  included do
    after_commit :web_sub_publish_later, on: [:create, :update]
  end

  private

  def web_sub_publish_later
    Activity::WebSubPublishJob.perform_later(
      Rails.application.routes.url_helpers.url_for([self, {only_path: false}])
    )
  end
end
