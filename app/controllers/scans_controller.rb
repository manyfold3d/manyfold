class ScansController < ApplicationController
  # Allowlist only: check | dedup | default detect (INIT-022/SPEC-009).
  # Unknown type stays on detect — never coerce dedup → check.
  def create
    authorize :scan
    # Load filters
    @filter = Search::FilterService.new(params, user: current_user)
    # Prune orphaned problems
    Upgrade::PruneOrphanedProblems.perform_later
    notice = enqueue_scan
    redirect_back_or_to models_path(@filter.to_params), notice: notice
  end

  private

  # Keep navbar Dedup keys live for SPEC-010 confirm copy (INIT-022/SPEC-009).
  def dedup_navbar_copy
    [t("application.navbar.dedup.label"), t("application.navbar.dedup.confirm")]
  end

  def enqueue_scan
    case params[:type].to_s
    when "check"
      Scan::CheckAllJob.perform_later(@filter.to_params, current_user)
      t(".success")
    when "dedup"
      Scan::DedupLibraryJob.perform_later
      t(".dedup_success")
    else
      Library.find_each do |library|
        library.detect_filesystem_changes_later
      end
      t(".success")
    end
  end
end
