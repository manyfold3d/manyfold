authenticate :user, lambda { |u| u.is_moderator? } do
  if SiteSettings.multiuser_enabled? || Rails.env.test?
    namespace :settings do
      resources :users, constraints: {id: /[^\/]+/}
      resources :reports
    end
  end
end
