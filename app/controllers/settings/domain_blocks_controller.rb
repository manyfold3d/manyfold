class Settings::DomainBlocksController < ApplicationController
  respond_to :html

  def index
    @blocks = policy_scope(Fedipub::Moderation::DomainBlock).all
    render layout: "settings"
  end

  def new
    authorize Fedipub::Moderation::DomainBlock
    @domain_block = Fedipub::Moderation::DomainBlock.new
    render layout: "settings"
  end

  def create
    authorize Fedipub::Moderation::DomainBlock
    @domain_block = Fedipub::Moderation::DomainBlock.create(domain_block_params)
    if @domain_block.valid?
      redirect_to settings_domain_blocks_path, notice: t(".success")
    else
      render :new, layout: "settings", status: :unprocessable_content
    end
  end

  def destroy
    @domain_block = policy_scope(Fedipub::Moderation::DomainBlock).find(params[:id])
    authorize @domain_block
    @domain_block.destroy
    redirect_to settings_domain_blocks_path, notice: t(".success")
  end

  private

  def domain_block_params
    params.expect(domain_block: [
      :domain # i18n-tasks-use t("activerecord.attributes.fedipub/moderation/domain_block.domain")
    ])
  end
end
