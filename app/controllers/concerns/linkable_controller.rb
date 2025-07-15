module LinkableController
  extend ActiveSupport::Concern

  def sync
    link = @linkable&.links&.find(params[:link])
    # Enqueue the sync
    link&.update_metadata_from_link_later
    # Back to the model page
    redirect_back_or_to @linkable, notice: link ? t("concerns.linkable.sync.success") : t("concerns.linkable.sync.bad_request")
  end
end
