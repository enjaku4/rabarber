# frozen_string_literal: true

class DummyApplication < Rails::Application; end

DummyApplication.configure do
  config.eager_load = true
  config.cache_store = :null_store
end

DummyApplication.initialize!

DummyApplication.routes.draw do
  root to: "dummy_pages#home"

  get "multiple_roles", to: "dummy#multiple_roles"
  post "single_role", to: "dummy#single_role"
  put "all_access", to: "dummy#all_access"
  delete "no_access", to: "dummy#no_access"
  post "multiple_rules", to: "dummy#multiple_rules"
  get "if_lambda", to: "dummy#if_lambda"
  post "if_method", to: "dummy#if_method"
  patch "unless_lambda", to: "dummy#unless_lambda"
  delete "unless_method", to: "dummy#unless_method"

  put "foo", to: "dummy_parent#foo"
  delete "bar", to: "dummy_parent#bar"

  post "baz", to: "dummy_child#baz"
  patch "bad", to: "dummy_child#bad"

  put "access_with_roles", to: "no_user#access_with_roles"
  get "all_access", to: "no_user#all_access"
  post "no_access", to: "no_user#no_access"

  delete "no_rules", to: "no_rules#no_rules"

  get "skip_no_rules", to: "skip_authorization#skip_no_rules"
  put "skip_rules", to: "skip_authorization#skip_rules"
  post "no_skip", to: "skip_authorization#no_skip"

  get "global_ctx", to: "context#global_ctx"
  post "class_ctx", to: "context#class_ctx"
  put "instance_ctx", to: "context#instance_ctx"
  patch "symbol_ctx", to: "context#symbol_ctx"
  delete "proc_ctx", to: "context#proc_ctx"

  get "api_action", to: "api#api_action"
end
