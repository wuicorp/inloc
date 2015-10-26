Rails.application.routes.draw do
  mount ResqueWeb::Engine => "/resque_web"

  root 'welcome#index'

  scope :api do
    scope :v1 do
      use_doorkeeper
    end
  end

  namespace :api do
    namespace :v1 do
      resources :flags, only: [:index, :create, :update, :destroy]
    end
  end
end
