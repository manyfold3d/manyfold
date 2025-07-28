class ScansController < ApplicationController
  def create
    authorize :scan
    @filters = {q: params[:q]}.compact
    # Prune orphaned problems
    Upgrade::PruneOrphanedProblems.perform_later
    if params[:type] === "check"
      # Get filter list
      Scan::CheckAllJob.perform_later(@filters)
    else
      Library.find_each do |library|
        library.detect_filesystem_changes_later
      end
    end
    redirect_back_or_to models_path(@filters), notice: t(".success")
  end
end
