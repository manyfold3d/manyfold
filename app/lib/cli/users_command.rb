require "thor"

module Cli
  class UsersCommand < Thor
    namespace :users
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

    desc "create", "create a new user"
    option :email, required: true, type: :string, aliases: :mail
    option :username, required: true, type: :string, aliases: :login
    option :password, required: true, type: :string
    option :role, required: false, type: :string, enum: %w[administrator moderator contributor member]
    def create
      u = User.create(
        username: options[:username],
        email: options[:email],
        password: options[:password],
        password_confirmation: options[:password_confirmation]
      )
      if u.valid?
        u.add_role(options[:role].to_sym) if options[:role]
        puts "\nNew user created OK"
      else
        puts "\nError when creating user:\n"
        puts u.errors.full_messages.inspect
      end
    end
  end
end
