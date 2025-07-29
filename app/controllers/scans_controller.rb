class ScansController < ApplicationController
  def create
    authorize :scan
    # Load filters
    @filter = Search::FilterService.new(params)
    # Prune orphaned problems
    Upgrade::PruneOrphanedProblems.perform_later
    if params[:type] === "check"
      # Get filter list
      Scan::CheckAllJob.perform_later(@filter.to_params, current_user)
    else
      Library.find_each do |library|
        library.detect_filesystem_changes_later
      end
    end
    redirect_back_or_to models_path(@filter.to_params), notice: t(".success")
  end
end
