# frozen_string_literal: true

if Rails.env.development?
  if File.directory? File.expand_path(".git")
    system("git fetch #{Rails.application.config.upstream_repo}")
    git_sha = `git rev-parse --short=8 HEAD`
    git_sha.strip!
    app_version = `git describe --tags --abbrev=0 #{git_sha}`
    app_version.strip!

    Rails.application.config.git_sha = git_sha
    Rails.application.config.app_version = app_version
  end
end
