# frozen_string_literal: true

version = "8.0.5.1"

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = "amiko"
  s.version     = version
  s.summary     = "Full-stack web application framework."
  s.description = "Amiko is a rails for that doesn't tolerate bigotry"

  s.required_ruby_version     = ">= 3.2.0"
  s.required_rubygems_version = ">= 1.8.11"

  s.license = "MIT"

  s.author   = ""
  s.email    = ""
  s.homepage = ""

  s.files = ["lib/amiko.rb"]

  s.metadata = {
  }

  s.add_dependency "activesupport", version
  s.add_dependency "actionpack",    version
  s.add_dependency "actionview",    version
  s.add_dependency "activemodel",   version
  s.add_dependency "activerecord",  version
  s.add_dependency "actionmailer",  version
  s.add_dependency "activejob",     version
  s.add_dependency "actioncable",   version
  s.add_dependency "activestorage", version
  s.add_dependency "actionmailbox", version
  s.add_dependency "actiontext",    version
  s.add_dependency "railties",      version

  s.add_dependency "bundler", ">= 1.15.0"
end
