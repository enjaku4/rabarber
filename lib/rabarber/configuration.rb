# frozen_string_literal: true

require "singleton"

module Rabarber
  class Configuration
    include Singleton

    attr_reader :audit_trail_enabled, :cache_enabled, :current_user_method
    attr_writer :user_model_name

    def initialize
      # TODO: consider nuking the feature in favor of the user implementing their own audit trail when needed
      @audit_trail_enabled = true
      @cache_enabled = true
      @current_user_method = :current_user
      # TODO: may enable habtm and other similar use cases
      @user_model_name = "User"
    end

    def audit_trail_enabled=(value)
      @audit_trail_enabled = Rabarber::Input::Types::Boolean.new(
        value, Rabarber::ConfigurationError, "Configuration 'audit_trail_enabled' must be a Boolean"
      ).process
    end

    def cache_enabled=(value)
      @cache_enabled = Rabarber::Input::Types::Boolean.new(
        value, Rabarber::ConfigurationError, "Configuration 'cache_enabled' must be a Boolean"
      ).process
    end

    def current_user_method=(method_name)
      @current_user_method = Rabarber::Input::Types::Symbol.new(
        method_name, Rabarber::ConfigurationError, "Configuration 'current_user_method' must be a Symbol or a String"
      ).process
    end

    def user_model
      Rabarber::Input::ArModel.new(
        @user_model_name, Rabarber::ConfigurationError, "Configuration 'user_model_name' must be an ActiveRecord model name"
      ).process
    end
  end
end
