# frozen_string_literal: true

require "dry-configurable"

module Rabarber
  module Configuration
    extend Dry::Configurable

    module_function

    setting :cache_enabled,
            default: true,
            reader: true,
            constructor: -> (value) do
              Rabarber::Input::Types::Boolean.new(
                value, Rabarber::ConfigurationError, "Configuration `cache_enabled` must be a Boolean"
              ).process
            end
    setting :current_user_method,
            default: :current_user,
            reader: true,
            constructor: -> (value) do
              Rabarber::Input::Types::Symbol.new(
                value, Rabarber::ConfigurationError, "Configuration `current_user_method` must be a Symbol or a String"
              ).process
            end
    setting :user_model_name,
            default: "User",
            reader: true # TODO: constructor check if the value is a non-empty String

    def user_model
      Rabarber::Input::ArModel.new(
        user_model_name, Rabarber::ConfigurationError, "Configuration `user_model_name` must be an ActiveRecord model name"
      ).process
    end
  end
end
