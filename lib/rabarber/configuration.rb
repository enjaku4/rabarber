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
      @current_user_method = Input::Types::Symbols.new(
        method_name, ConfigurationError, "Configuration 'current_user_method' must be a Symbol or a String"
      ).process
    end

    def must_have_roles=(value)
      @must_have_roles = Input::Types::Booleans.new(
        value, ConfigurationError, "Configuration 'must_have_roles' must be a Boolean"
      ).process
    end

    def when_unauthorized=(callable)
      @when_unauthorized = Input::Types::Callables.new(
        callable, ConfigurationError, "Configuration 'when_unauthorized' must be a Proc"
      ).process
    end
  end
end
