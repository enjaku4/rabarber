# frozen_string_literal: true

module Rabarber
  class Configuration
    include Singleton

    attr_reader :audit_trail_enabled, :cache_enabled, :current_user_method, :must_have_roles,
                :when_actions_missing, :when_roles_missing, :when_unauthorized

    def initialize
      @audit_trail_enabled = default_audit_trail_enabled
      @cache_enabled = default_cache_enabled
      @current_user_method = default_current_user_method
      @must_have_roles = default_must_have_roles
      @when_actions_missing = default_when_actions_missing
      @when_roles_missing = default_when_roles_missing
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

    def when_actions_missing=(callable)
      @when_actions_missing = Rabarber::Input::Types::Proc.new(
        callable, Rabarber::ConfigurationError, "Configuration 'when_actions_missing' must be a Proc"
      ).process
    end

    def when_roles_missing=(callable)
      @when_roles_missing = Rabarber::Input::Types::Proc.new(
        callable, Rabarber::ConfigurationError, "Configuration 'when_roles_missing' must be a Proc"
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

    def default_when_actions_missing
      -> (missing_actions, context) {
        raise(Rabarber::Error, "'grant_access' method called with non-existent actions: #{missing_actions}, context: '#{context[:controller]}'")
      }
    end

    def default_when_roles_missing
      -> (missing_roles, context) {
        delimiter = context[:action] ? "#" : ""
        message = "'grant_access' method called with non-existent roles: #{missing_roles}, context: '#{context[:controller]}#{delimiter}#{context[:action]}'"
        Rabarber::Logger.log(:warn, message)
      }
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
