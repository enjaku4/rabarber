# frozen_string_literal: true

module Rabarber
  class Configuration
    include Singleton

    attr_reader :audit_trail_enabled, :cache_enabled, :current_user_method, :must_have_roles, :when_unauthorized

    def initialize
      @audit_trail_enabled = default_audit_trail_enabled
      @cache_enabled = default_cache_enabled
      @current_user_method = default_current_user_method
      @must_have_roles = default_must_have_roles
      @when_unauthorized = default_when_unauthorized
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

    def when_unauthorized=(callable)
      @when_unauthorized = Rabarber::Input::Types::Proc.new(
        callable, Rabarber::ConfigurationError, "Configuration 'when_unauthorized' must be a Proc"
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

    def default_when_unauthorized
      -> (controller) do
        if controller.request.format.html?
          controller.redirect_back fallback_location: controller.main_app.root_path
        else
          controller.head(:unauthorized)
        end
      end
    end
  end
end
