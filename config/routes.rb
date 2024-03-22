Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  get 'common_ancestor' => 'application#common_ancestor'
  get 'birds' => 'application#birds'
  post 'seed_data_from_csv' => 'application#seed_data_from_csv'
  delete 'delete_all_data' => 'application#delete_all_data'
end
