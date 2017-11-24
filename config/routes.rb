Spree::Core::Engine.routes.draw do
  resources :orders do
    resources :return_authorizations, only: [:new, :create, :show]
  end
  resources :return_authorizations, only: :index

  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      resources :return_authorizations do
        collection do
          get :my_returns
          get 'my_return/:id', to: 'return_authorizations#my_return'
          get 'new_return/:order_id', to: 'return_authorizations#new_return'
          post :user_return
        end
      end
    end
  end
end
