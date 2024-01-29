# frozen_string_literal: true

class DummyApplication < Rails::Application; end

DummyApplication.configure do
  config.eager_load = true
  # TODO: need to write tests specifically for the case when caching is enabled
  config.cache_store = :null_store
end

DummyApplication.initialize!

DummyApplication.routes.draw do
  root to: "dummy_pages#home"

  get "multiple_roles", to: "dummy#multiple_roles"
  post "single_role", to: "dummy#single_role"
  put "all_access", to: "dummy#all_access"
  delete "no_access", to: "dummy#no_access"
  get "if_lambda", to: "dummy#if_lambda"
  post "if_method", to: "dummy#if_method"
  patch "unless_lambda", to: "dummy#unless_lambda"
  delete "unless_method", to: "dummy#unless_method"

  put "foo", to: "dummy_parent#foo"
  delete "bar", to: "dummy_parent#bar"

  post "baz", to: "dummy_child#baz"
  patch "bad", to: "dummy_child#bad"
end
