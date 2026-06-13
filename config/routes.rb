Rails.application.routes.draw do
  get "settings/edit"
  get "settings/update"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # 日付ベースのルート（メイン）
  get "/day/:date", to: "pages#show", as: :date
  post "/day/:date", to: "pages#create", as: :create_date_page
  patch "/day/:date", to: "pages#update", as: :update_date_page
  delete "/day/:date", to: "pages#destroy", as: :destroy_date_page
  post "/day/:date/analyze", to: "pages#analyze", as: :analyze_date_page

  # その他のルート
  get "/pages", to: "pages#index", as: :pages
  get "/pages/:month", to: "pages#index", as: :pages_month
  get "/ask", to: "ask#index", as: :ask
  post "/ask", to: "ask#create"
  get "/search", to: "pages#search", as: :search
  get "/view", to: "pages#view", as: :view
  get "/about", to: "pages#about", as: :about
  get "/today", to: "pages#today", as: :today
  get "/random", to: "pages#random", as: :random
  get "/try", to: "pages#try", as: :try
  get "/review", to: "pages#review", as: :review
  get "/review/:date", to: "pages#review", as: :review_date
  post "/analyze_week", to: "pages#analyze_week"
  post "/analyze_all", to: "pages#analyze_all", as: :analyze_all
  post "/check_batch", to: "pages#check_batch", as: :check_batch

 get "/settings", to: "settings#edit", as: :settings
  patch "/settings", to: "settings#update", as: :update_settings

  get "/planner", to: "planner#index", as: :planner
  get "/planner/clean", to: "planner#clean", as: :planner_clean
  get "/planner/meet", to: "planner#meet", as: :planner_meet
  get "/planner/bath", to: "planner#bath", as: :planner_bath
  get "/planner/everyday", to: "planner#everyday", as: :planner_everyday
  get "/planner/weather", to: "planner#weather", as: :planner_weather
  get "/planner/today", to: "planner#today", as: :planner_today
  get "/planner/meal", to: "planner#meal", as: :planner_meal

  resources :planner_items, only: %i[create update destroy]
  resources :planner_lists, only: %i[update]

  root "pages#index"
end
