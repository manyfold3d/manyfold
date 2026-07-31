# frozen_string_literal: true

Amiko.application.config.upstream_repo = ENV.fetch("UPSTREAM_REPO", "https://github.com/manyfold3d/manyfold")
Amiko.application.config.app_version = ENV.fetch("APP_VERSION", "unknown").split(":")[-1]
Amiko.application.config.git_sha = ENV.fetch("GIT_SHA", "main")

if Amiko.env.development?
  if File.directory? File.expand_path(".git")
    system("git fetch #{Amiko.application.config.upstream_repo}")
    git_sha = `git rev-parse HEAD`
    git_sha.strip!
    app_version = `git describe --tags --abbrev=0 #{git_sha}`
    app_version.strip!

    Amiko.application.config.git_sha = git_sha
    Amiko.application.config.app_version = app_version
  end
end
