Rails.application.routes.draw do
  # Authentication routes with custom controllers
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    confirmations: "users/confirmations",
    passwords: "users/passwords"
  }

  # Dashboard routes
  get "dashboard", to: "dashboard#index"

  # Organization routes
  resources :organizations, only: [ :index, :show, :new, :create ]

  # Automated Testing routes
  namespace :automated_testing do
    get "upload", to: "upload#index"
    post "upload", to: "upload#create"
    resources :results, only: [ :index, :show, :edit, :update, :destroy ] do
      member do
        get :download_xml
        get "test_results/:test_result_id", to: "results#test_result", as: :test_result
      end
    end
  end

  # Manual Testing routes
  namespace :manual_testing do
    get "cases", to: "test_cases#index"
    resources :test_cases, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]
  end

  # System Admin routes
  namespace :system_admin do
    get "dashboard", to: "dashboard#index"

    resources :organizations do
      member do
        post "add_user"
        delete "remove_user"
        patch "change_user_role"
      end
    end

    resources :users do
      member do
        patch "lock"
        patch "unlock"
        patch "confirm"
        patch "resend_confirmation"
      end
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"

  get "home/index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
