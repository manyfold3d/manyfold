class ModeratorMailer < ApplicationMailer
  def new_report
    # i18n-tasks-use t('moderator_mailer.new_report.subject')
    @mod = params[:moderator]
    @report = params[:report]
    mail to: @mod.email
  end

  def new_approval
    # i18n-tasks-use t('moderator_mailer.new_approval.subject')
    @mod = params[:moderator]
    @user = params[:user]
    mail to: @mod.email
  end
end
