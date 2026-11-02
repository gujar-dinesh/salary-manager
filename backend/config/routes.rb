Rails.application.routes.draw do
  namespace :api do
    resources :employees do
      get :options, on: :collection
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
