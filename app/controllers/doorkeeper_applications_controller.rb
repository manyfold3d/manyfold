class DoorkeeperApplicationsController < ApplicationController
  before_action :get_application, except: [:index, :new, :create]

  def index
    @applications = policy_scope(Doorkeeper::Application)
    # i18n-tasks-use t("activerecord.attributes.doorkeeper/application.created_at")
    # i18n-tasks-use t("activerecord.attributes.doorkeeper/application.owner")
  end

  def show
    @access_tokens = @application.access_tokens
    # i18n-tasks-use t("activerecord.attributes.doorkeeper/application.uid")
    # i18n-tasks-use t("activerecord.attributes.doorkeeper/application.secret")
  end

  def new
    authorize Doorkeeper::Application
    @application = Doorkeeper::Application.new(
      redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
      scopes: Doorkeeper.configuration.default_scopes
    )
  end

  def edit
  end

  def create
    authorize Doorkeeper::Application
    @application = Doorkeeper::Application.create(application_params.merge(owner: current_user))
    if @application.valid?
      redirect_to @application, notice: t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :new, status: :unprocessable_content
    end
  end

  def update
    @application.update(application_params)
    if @application.save
      redirect_to @application, notice: t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @application.destroy
    redirect_to doorkeeper_applications_path, notice: t(".success")
  end

  private

  def application_params
    params.expect(doorkeeper_application: [
      :name, # i18n-tasks-use t("activerecord.attributes.doorkeeper/application.name")
      :redirect_uri, # i18n-tasks-use t("activerecord.attributes.doorkeeper/application.redirect_uri")
      :confidential, # i18n-tasks-use t("activerecord.attributes.doorkeeper/application.confidential")
      scopes: [] # i18n-tasks-use t("activerecord.attributes.doorkeeper/application.scopes")
    ])
  end

  def get_application
    @application = policy_scope(Doorkeeper::Application).find(params[:id])
    authorize @application
  end
end
