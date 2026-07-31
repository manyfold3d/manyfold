authenticate :user, lambda { |u| u.is_moderator? } do
  if SiteSettings.multiuser_enabled? || Amiko.env.test?
    namespace :settings do
      resources :users, constraints: {id: /[^\/]+/}
      resources :reports
    end
  end
end
