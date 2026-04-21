get "/altcha", to: "altcha#new"
get ".well-known/change-password", to: redirect("/users/edit")

devise_controllers = {
  passwords: "users/passwords",
  registrations: "users/registrations",
  sessions: "users/sessions",
  invitations: "users/invitations"
}

devise_controllers[:omniauth_callbacks] = "users/omniauth_callbacks" if Rails.application.config.manyfold_features[:oidc]

devise_for :users, controllers: devise_controllers
