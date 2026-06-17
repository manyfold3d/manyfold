class PrintHostsController < ApplicationController
  layout "settings"
  before_action :get_print_host, except: [:index, :new, :create]

  def index
    authorize PrintHost
    @print_hosts = policy_scope(PrintHost).all
    respond_to do |format|
      format.html { render Views::PrintHosts::Index.new(print_hosts: @print_hosts) }
    end
  end

  def new
    @print_host = PrintHost.new
    authorize @print_host
    respond_to do |format|
      format.html { render Views::PrintHosts::New.new(print_host: @print_host) }
    end
  end

  def edit
    respond_to do |format|
      format.html { render Views::PrintHosts::Edit.new(print_host: @print_host) }
    end
  end

  def create
    @print_host = PrintHost.new(print_host_params)
    authorize @print_host
    respond_to do |format|
      format.html do
        if @print_host.save
          redirect_to print_hosts_path, notice: t(".success")
        else
          render Views::PrintHosts::New.new(print_host: @print_host), status: :unprocessable_content
        end
      end
    end
  end

  def update
    respond_to do |format|
      format.html do
        if @print_host.update(print_host_params)
          redirect_back_or_to print_hosts_path, notice: t(".success"), status: :see_other
        else
          render Views::PrintHosts::Edit.new(print_host: @print_host), status: :unprocessable_content
        end
      end
    end
  end

  def destroy
    @print_host.destroy!
    respond_to do |format|
      format.html { redirect_to print_hosts_path, notice: t(".success"), status: :see_other }
    end
  end

  def print
    @file = ModelFile.find_param(params[:file_id])
    authorize @file
    @print_host.print_later(file: @file)
    redirect_back_or_to model_model_file_path(@file.model, @file), notice: t(".sent"), status: :see_other
  end

  private

  def print_host_params
    params.require(:print_host).permit( # rubocop:todo Rails/StrongParametersExpect
      :name, # i18n-tasks-use t("activerecord.attributes.print_host.name")
      :endpoint, # i18n-tasks-use t("activerecord.attributes.print_host.endpoint")
      :protocol, # i18n-tasks-use t("activerecord.attributes.print_host.protocol")
      :credentials # i18n-tasks-use t("activerecord.attributes.print_host.credentials")
    )
  end

  def get_print_host
    @print_host = policy_scope(PrintHost).find(params[:id])
    authorize @print_host
  end
end
