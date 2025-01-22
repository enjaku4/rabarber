# frozen_string_literal: true

class DummyApplication < Rails::Application
  config.eager_load = true
  config.cache_store = :null_store
end

DummyApplication.initialize!

DummyApplication.routes.draw do
  root to: "dummy_pages#home"

  resources :dummy, only: [] do
    collection do
      get :multiple_roles
      post :single_role
      put :all_access
      delete :no_access
      post :multiple_rules
      get :if_lambda
      post :if_method
      patch :unless_lambda
      delete :unless_method
    end
  end

  resources :dummy_parent, only: [] do
    collection do
      put :foo
      delete :bar
    end
  end

  resources :dummy_child, only: [] do
    collection do
      post :baz
      patch :bad
    end
  end

  resources :multiple_rules, only: [] do
    delete :qux, on: :collection
  end

  resources :all_access, only: [] do
    get :quux, on: :collection
  end

  resources :no_user, only: [] do
    collection do
      put :access_with_roles
      get :all_access
      post :no_access
    end
  end

  resources :no_rules, only: [] do
    delete :no_rules, on: :collection
  end

  resources :skip_authorization, only: [] do
    collection do
      get :skip_no_rules
      put :skip_rules
      post :no_skip
    end
  end

  resources :context, only: [] do
    collection do
      get :global_ctx
      post :class_ctx
      put :instance_ctx
      patch :symbol_ctx
      delete :proc_ctx
    end
  end

  get "api_action", to: "api#api_action"
end
