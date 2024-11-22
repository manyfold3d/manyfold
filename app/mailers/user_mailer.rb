class UserMailer < ApplicationMailer
  def account_approved
    @user = params[:user]
    mail to: @user.email
  end
end
