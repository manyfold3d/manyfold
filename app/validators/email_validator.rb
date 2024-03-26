require 'uri'

class EmailValidator < ActiveModel::Validator
  def validate(record)
    record.errors.add(:email, I18n.t('errors.messages.invalid')) unless record.email.match? URI::MailTo::EMAIL_REGEXP
  end
end
