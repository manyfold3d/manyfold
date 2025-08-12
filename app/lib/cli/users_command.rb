require "thor"

module Cli
  class UsersCommand < Thor
    COMMAND = "users"
    DESCRIPTION = "manage users"

    desc "approve", "approves a user"
    option :email, required: true, type: :string, aliases: :mail
    def approve
      u = User.find_by(email: options[:email])
      raise "User not found" if u.nil?
      u.update(approved: true)
      puts "\nUser #{u.email} approved"
    rescue RuntimeError
      puts "\nUser #{options[:email]} not found"
    end

    desc "password", "resets password for user"
    option :email, required: true, type: :string, aliases: :mail
    def password
      u = User.find_by(email: options[:email])
      raise "User not found" if u.nil?
      u.password = ask("Enter password: ", echo: false)
      puts "\n"
      u.password_confirmation = ask("Confirm password: ", echo: false)
      puts "\nPassword changed!" if u.save!
    rescue ActiveRecord::RecordInvalid => e
      puts "\n#{e}"
    rescue RuntimeError => e
      puts "\n#{e}"
    end
  end
end
