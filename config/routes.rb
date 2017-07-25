Rails.application.routes.draw do
  root "crawler#index"
  get "crawler_web" => "crawler#thieving"

  resources :posts, only: :index
end
