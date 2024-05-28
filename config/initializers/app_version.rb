# frozen_string_literal: true

Rails.application.config.upstream_repo = ENV.fetch("UPSTREAM_REPO", "https://github.com/manyfold3d/manyfold")
Rails.application.config.app_version = ENV.fetch("APP_VERSION", "unknown").split(":")[-1]
Rails.application.config.git_sha = ENV.fetch("GIT_SHA", "main")

if Rails.env.development?
  if File.directory? File.expand_path(".git")
    system("git fetch #{Rails.application.config.upstream_repo}")
    git_sha = `git rev-parse HEAD`
    git_sha.strip!
    app_version = `git describe --tags --abbrev=0 #{git_sha}`
    app_version.strip!

    Rails.application.config.git_sha = git_sha
    Rails.application.config.app_version = app_version
  end
end
