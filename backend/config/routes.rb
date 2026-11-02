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

  root "frontend#index"
  # Client-side routes: anything outside /api that is not a file (no extension), whatever the Accept header.
  get "*path", to: "frontend#index", format: false,
               constraints: ->(request) { !request.path.start_with?("/api/") && !request.path.match?(/\.\w+\z/) }
end
