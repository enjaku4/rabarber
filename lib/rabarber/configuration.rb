# frozen_string_literal: true

require "singleton"

module Rabarber
  class Configuration
    include Singleton

    attr_reader :current_user_method, :must_have_roles, :when_actions_missing, :when_roles_missing, :when_unauthorized

    def initialize
      @current_user_method = :current_user
      @must_have_roles = false
      @when_actions_missing = ->(missing_actions, context) {
        raise Rabarber::Error, "Missing actions: #{missing_actions}, context: #{context[:controller]}"
      }
      @when_roles_missing = ->(missing_roles, context) {
        delimiter = context[:action] ? "#" : ""
        message = "Missing roles: #{missing_roles}, context: #{context[:controller]}#{delimiter}#{context[:action]}"
        Rails.logger.tagged("Rabarber") { Rails.logger.warn message }
      }
      @when_unauthorized = ->(controller) do
        if controller.request.format.html?
          controller.redirect_back fallback_location: controller.main_app.root_path
        else
          controller.head(:unauthorized)
        end
      end
    end

    def current_user_method=(method_name)
      @current_user_method = Rabarber::Input::Types::Symbols.new(
        method_name, Rabarber::ConfigurationError, "Configuration 'current_user_method' must be a Symbol or a String"
      ).process
    end

    def must_have_roles=(value)
      @must_have_roles = Rabarber::Input::Types::Booleans.new(
        value, Rabarber::ConfigurationError, "Configuration 'must_have_roles' must be a Boolean"
      ).process
    end

    def when_roles_missing=(callable)
      @when_roles_missing = Rabarber::Input::Types::Procs.new(
        callable, Rabarber::ConfigurationError, "Configuration 'when_roles_missing' must be a Proc"
      ).process
    end

    def when_unauthorized=(callable)
      @when_unauthorized = Rabarber::Input::Types::Procs.new(
        callable, Rabarber::ConfigurationError, "Configuration 'when_unauthorized' must be a Proc"
      ).process
    end
  end
end
