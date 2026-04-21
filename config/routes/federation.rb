if SiteSettings.federation_enabled? || Rails.env.test?

  # Core federation capability

  mount Federails::Engine => "/"
  scope Federails.configuration.server_routes_path, module: "federails/server", as: "federails_server", defaults: {format: :activitypub} do
    resources :quote_authorizations, only: [:show]
  end

  # Remote follow routes

  get "/authorize_interaction" => "follows#new" # for compatibility with Mastodon, which assumes this URL
  post "/remote_follow" => "follows#remote_follow", :as => :remote_follow
  post "/perform_remote_follow" => "follows#perform_remote_follow", :as => :perform_remote_follow
  authenticate :user do
    post "/follow_remote_actor/:id" => "follows#follow_remote_actor", :as => :follow_remote_actor
    delete "/follow_remote_actor/:id" => "follows#unfollow_remote_actor", :as => :unfollow_remote_actor
  end

  # Moderation

  authenticate :user, lambda { |u| u.is_moderator? } do
    namespace :settings do
      resources :domain_blocks
    end
  end

  # FASP integration

  mount FaspClient::Engine => "/fasp"

end
