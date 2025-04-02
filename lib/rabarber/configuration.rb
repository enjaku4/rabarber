# frozen_string_literal: true

require "singleton"

module Rabarber
  class Configuration
    include Singleton

    attr_reader :audit_trail_enabled, :cache_enabled, :current_user_method

    def initialize
      @audit_trail_enabled = true
      @cache_enabled = true
      @current_user_method = :current_user
    end

    def cache_enabled=(value)
      @cache_enabled = Rabarber::Input::Types::Boolean.new(
        value, Rabarber::ConfigurationError, "Configuration 'cache_enabled' must be a Boolean"
      ).process
    end

    def audit_trail_enabled=(value)
      @audit_trail_enabled = Rabarber::Input::Types::Boolean.new(
        value, Rabarber::ConfigurationError, "Configuration 'audit_trail_enabled' must be a Boolean"
      ).process
    end

    def current_user_method=(method_name)
      @current_user_method = Rabarber::Input::Types::Symbol.new(
        method_name, Rabarber::ConfigurationError, "Configuration 'current_user_method' must be a Symbol or a String"
      ).process
    end
  end
end
