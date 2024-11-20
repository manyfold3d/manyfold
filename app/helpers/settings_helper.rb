module SettingsHelper
  def masked_email(email)
    email.gsub(/(?<=^.)[^@]*|(?<=@.).*(?=\.[^.]+$)/, "****")
  end
end
