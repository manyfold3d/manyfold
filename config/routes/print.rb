resources :print_hosts, except: [:show] do
  member do
    post :print
  end
end
