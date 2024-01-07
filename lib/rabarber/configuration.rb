# frozen_string_literal: true

require "singleton"

module Rabarber
  class Configuration
    include Singleton

    attr_reader :current_user_method, :must_have_roles, :when_unauthorized

    def initialize
      @current_user_method = :current_user
      @must_have_roles = false
      @when_unauthorized = ->(controller) do
        if controller.request.format.html?
          controller.redirect_back fallback_location: controller.main_app.root_path
        else
          controller.head(:unauthorized)
        end
      end
    end

    def current_user_method=(method_name)
      unless method_name.is_a?(Symbol) || method_name.is_a?(String)
        raise ConfigurationError, "Configuration 'current_user_method' must be a Symbol or a String"
      end

      @current_user_method = method_name.to_sym
    end

    def must_have_roles=(value)
      raise ConfigurationError, "Configuration 'must_have_roles' must be a Boolean" unless [true, false].include?(value)

      @must_have_roles = value
    end

    def when_unauthorized=(callable)
      raise ConfigurationError, "Configuration 'when_unauthorized' must be a Proc" unless callable.is_a?(Proc)

      @when_unauthorized = callable
    end
  end
end
