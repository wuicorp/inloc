Rails.application.routes.draw do
  root 'welcome#index'

  scope :api do
    scope :v1 do
      use_doorkeeper
    end
  end
end
