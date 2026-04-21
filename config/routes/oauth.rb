use_doorkeeper do
  skip_controllers :applications, :tokens
end
resources :doorkeeper_tokens, path: "/oauth/token"

authenticate :user do
  resources :doorkeeper_applications, path: "/oauth/applications" do
    resources :doorkeeper_access_tokens, except: [:index, :edit, :update], path: "tokens"
  end
end
