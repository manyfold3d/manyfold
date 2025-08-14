module ModelsController::Merge
  extend ActiveSupport::Concern

  included do
    skip_before_action :get_model, only: [:merge, :configure_merge]

    before_action :get_merge_params, only: [:merge, :configure_merge]
    before_action :get_merging_models, only: [:merge, :configure_merge]

    after_action :verify_policy_scoped, only: [:merge, :configure_merge]
  end

  def configure_merge
    skip_authorization
    @common_root = Model.common_root(*@models)
    @common_root = nil if Model.find_by(path: @common_root)
  end

  def merge
    @target = nil
    @template = nil
    if @merge_params[:target] == "==new=="
      @target = Model.create_from(@models.first, name: @models.first.name)
    elsif @merge_params[:target] == "==common_root=="
      path = Model.common_root(*@models)
      name = File.basename(path).humanize.tr("+", " ").careful_titleize
      @target = Model.create_from(@models.first, name: name, path: path)
    elsif @merge_params[:target]
      @target = Model.find_param(@merge_params[:target])
    end
    if @target
      authorize @target
      @target.merge!(@models)
      redirect_to @target, notice: t("models.merge.success")
    else
      skip_authorization
      redirect_to configure_merge_models_path(models: @models.map(&:public_id))
    end
  end

  private

  def get_merge_params
    if params[:models].respond_to?(:keys)
      params[:models] = params[:models].select { |k, v| v == "1" }.keys
    end
    @merge_params = params.permit(
      :target,
      models: []
    )
    if @merge_params[:models].blank?
      skip_authorization
      skip_policy_scope
      head :bad_request
    end
  end

  def get_merging_models
    model_ids = @merge_params[:models].without(@merge_params[:target])
    @models = policy_scope(Model, policy_scope_class: ApplicationPolicy::UpdateScope).local.where(public_id: model_ids)
    if @models.count != model_ids.count
      skip_authorization
      head :forbidden
    end
  end
end
