# frozen_string_literal: true

require "singleton"

module Rabarber
  class Configuration
    include Singleton

    attr_reader :audit_trail_enabled, :cache_enabled, :current_user_method, :user_model

    def initialize
      @audit_trail_enabled = true
      @cache_enabled = true
      @current_user_method = :current_user
      # TODO: consider using a string instead of a class, may enable habtm and prevent load issues
      # TODO: user_model_name, and the input is Rabarber::Input::ArModelName in this case
      @user_model = User
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

    def user_model=(model_class)
      @user_model = Rabarber::Input::Types::ArModel.new(
        model_class, Rabarber::ConfigurationError, "Configuration 'user_model' must be an ActiveRecord model"
      ).process
    end
  end
end
