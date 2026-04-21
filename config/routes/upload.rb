authenticate :user, lambda { |u| u.is_contributor? } do
  mount Tus::Server => "/upload", :as => :upload
end
