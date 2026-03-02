# frozen_string_literal: true

require "singleton"

module Rabarber
  class Configuration
    include Singleton

    attr_reader :cache_enabled, :current_user_method, :user_model_name

    def initialize
      reset_to_defaults!
    end

    def cache_enabled=(value)
      @cache_enabled = Rabarber::Inputs::Boolean.new(
        value,
        error: Rabarber::ConfigurationError,
        message: "Invalid configuration `cache_enabled`, expected a boolean, got #{value.inspect}"
      ).process
    end

    def current_user_method=(value)
      @current_user_method = Rabarber::Inputs::NonEmptySymbol.new(
        value,
        error: Rabarber::ConfigurationError,
        message: "Invalid configuration `current_user_method`, expected a symbol or a string, got #{value.inspect}"
      ).process
    end

    def user_model_name=(value)
      @user_model_name = Rabarber::Inputs::NonEmptyString.new(
        value,
        error: Rabarber::ConfigurationError,
        message: "Invalid configuration `user_model_name`, expected an ActiveRecord model name, got #{value.inspect}"
      ).process
    end

    def reset_to_defaults!
      self.cache_enabled = true
      self.current_user_method = :current_user
      self.user_model_name = "User"
    end

    def user_model
      Rabarber::Inputs::Model.new(
        user_model_name,
        error: Rabarber::ConfigurationError,
        message: "Invalid configuration `user_model_name`, expected an ActiveRecord model name, got #{user_model_name.inspect}"
      ).process
    end

    def configure
      yield self
    end

    class << self
      delegate :cache_enabled, :current_user_method, :user_model_name,
               :cache_enabled=, :current_user_method=, :user_model_name=,
               :user_model, :reset_to_defaults!, :configure,
               to: :instance
    end
  end
end
