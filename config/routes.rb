Rails.application.routes.draw do
  get 'home', to: 'home#index'
  get 'pricing', to: 'home#pricing'
  get 'about-us', to: 'home#about_us'
  get 'contacts', to: 'home#contacts'

  get '/404', to: 'errors#not_found'
  get '/422', to: 'errors#unacceptable'
  get '/500', to: 'errors#internal_error'

  devise_for :users, path: 'account', controllers: {
    registrations: 'users/registrations', sessions: 'users/track_sessions'
  }

  namespace :account do
    # concern :commentable do
    #   resources :comments, only: %i[create destroy]
    # end
    root 'dashboard#index'
    resources :companies do
      resources :pages, only: %i[show index] do
        patch :rate, on: :member
      end
      get :download, on: :member
      collection do
        resource :chrome_extensions, only: %i[new create]
      end
    end
    resources :comments, only: %i[create destroy]
    resources :tenants, only: %i[show index]
    resource :my_tenant, only: %i[show edit update]
    resources :analytics, only: %i[index]
    resources :users do
      post :impersonate, on: :member
      post :stop_impersonating, on: :collection
    end
    get 'chart-for-users-by-week',     to: 'charts#registered_users'
    get 'chart-for-companies-by-week', to: 'charts#created_companies'
    get 'chart-for-users-by-month',    to: 'charts#registered_users_summary'
    get 'chart-for-users-logins',      to: 'charts#users_logins'
  end

  authenticated :user do
    root 'account/dashboard#index', as: :authenticated_root
  end

  root 'home#index'
end
