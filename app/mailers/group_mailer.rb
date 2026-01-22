class GroupMailer < ApplicationMailer
  def new_member
    @user = params[:notification].recipient
    @group = params[:membership].group
    @inviting = @user.invitation_token.present? && @user.invitation_sent_at.blank?

    params = {to: @user.email}
    if @inviting
      params[:subject] = t("group_mailer.new_member.inviting.subject", site_name: SiteSettings.site_name)
      @user.invitation_sent_at = DateTime.now
      @user.save!(validate: false)
    else
      params[:subject] = t("group_mailer.new_member.existing.subject", site_name: SiteSettings.site_name)
    end

    mail(params)
  end
end
