class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("SMTP_FROM_ADDRESS", "notifications@#{ENV.fetch("PUBLIC_HOSTNAME", "localhost")}")
  layout "mailer"
end
