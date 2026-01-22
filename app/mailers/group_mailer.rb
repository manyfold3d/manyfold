class GroupMailer < ApplicationMailer
  def new_member
    @user = params[:notification].recipient
    @group = params[:membership].group
    @inviting = @user.invitation_token.present? && @user.invitation_sent_at.blank?

    params = {to: @user.email}
    if @inviting
      params[:subject] = t("group_mailer.new_member.inviting.subject", site_name: SiteSettings.site_name)
      # Generate a new invitation token so we have everything we need
      @user.invitation_sent_at = DateTime.now.utc
      @user.send :generate_invitation_token!
    else
      params[:subject] = t("group_mailer.new_member.existing.subject", site_name: SiteSettings.site_name)
    end

    mail(params)
  end
end
