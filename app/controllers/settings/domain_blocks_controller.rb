class Settings::DomainBlocksController < ApplicationController
  respond_to :html

  def index
    @blocks = policy_scope(Federails::Moderation::DomainBlock).all
    render layout: "settings"
  end

  def new
    authorize Federails::Moderation::DomainBlock
    @domain_block = Federails::Moderation::DomainBlock.new
    render layout: "settings"
  end

  def create
    authorize Federails::Moderation::DomainBlock
    @domain_block = Federails::Moderation::DomainBlock.create(domain_block_params)
    if @domain_block.valid?
      redirect_to settings_domain_blocks_path, notice: t(".success")
    else
      render :new, layout: "settings", status: :unprocessable_content
    end
  end

  def destroy
    @domain_block = policy_scope(Federails::Moderation::DomainBlock).find(params[:id])
    authorize @domain_block
    @domain_block.destroy
    redirect_to settings_domain_blocks_path, notice: t(".success")
  end

  private

  def domain_block_params
    params.expect(domain_block: [
      :domain
    ])
  end
end
