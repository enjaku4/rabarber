# frozen_string_literal: true

module Rabarber
  class Configuration
    include Singleton

    attr_reader :audit_trail_enabled, :cache_enabled, :current_user_method, :must_have_roles

    def initialize
      @audit_trail_enabled = default_audit_trail_enabled
      @cache_enabled = default_cache_enabled
      @current_user_method = default_current_user_method
      @must_have_roles = default_must_have_roles
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

    def must_have_roles=(value)
      @must_have_roles = Rabarber::Input::Types::Boolean.new(
        value, Rabarber::ConfigurationError, "Configuration 'must_have_roles' must be a Boolean"
      ).process
    end

    private

    def default_audit_trail_enabled
      true
    end

    def default_cache_enabled
      true
    end

    def default_current_user_method
      :current_user
    end

    def default_must_have_roles
      false
    end
  end
end
