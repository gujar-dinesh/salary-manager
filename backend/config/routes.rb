Rails.application.routes.draw do
  namespace :api do
    resources :employees do
      get :options, on: :collection
    end

    get "insights/countries", to: "insights#countries"
    get "insights/job_titles", to: "insights#job_titles"
    get "insights/overview", to: "insights#overview"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
