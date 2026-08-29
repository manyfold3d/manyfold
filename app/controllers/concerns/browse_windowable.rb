# frozen_string_literal: true

# Shared offset/page window math for BrowseGrid indexes (INIT-003/SPEC-002).
# Sets @browse_* ivars used by browse_window_meta / infinite-scroll sentinels.
module BrowseWindowable
  extend ActiveSupport::Concern

  private

  # Apply Kaminari first-page or offset stream window to +scope+.
  # Pass +total:+ when the caller already counted (e.g. before includes) — preferred
  # so HTML and stream paths avoid a second COUNT after eager-load joins (INIT-009/SPEC-005).
  def prepare_browse_window(scope, total: nil)
    stream = infinite_scroll_or_stream_request?
    per_page = BrowseGrid.page_size_for_request(params, stream: stream)
    @browse_per_page = per_page

    if stream && params[:offset].present?
      offset = BrowseGrid.offset_for_request(params)
      @browse_offset = offset
      total_count = total.nil? ? scope.count : total
      @browse_total_count = total_count
      result = scope.offset(offset).limit(per_page)
      records = result.load
      @browse_returned_count = records.size
      @browse_has_more_after = (offset + records.size) < total_count
      @browse_has_more_before = offset.positive?
      @browse_window = params[:window].presence_in(%w[before after]) || "after"
      result
    else
      page = if stream
        params[:page].presence || 1
      else
        1
      end
      result = scope.page(page).per(per_page)
      @browse_offset = (page.to_i - 1) * per_page
      @browse_total_count = total.nil? ? result.total_count : total
      @browse_returned_count = result.size
      @browse_has_more_after = if total.nil?
        result.next_page.present?
      else
        (@browse_offset + @browse_returned_count) < total
      end
      @browse_has_more_before = page.to_i > 1
      @browse_window = "after"
      result
    end
  end
end
