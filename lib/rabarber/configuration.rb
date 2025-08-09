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
              Rabarber::Inputs::Boolean.new(
                value,
                error: Rabarber::ConfigurationError,
                message: "Invalid configuration `cache_enabled`, expected a boolean, got #{value.inspect}"
              ).process
            end
    setting :current_user_method,
            default: :current_user,
            reader: true,
            constructor: -> (value) do
              Rabarber::Inputs::Symbol.new(
                value,
                error: Rabarber::ConfigurationError,
                message: "Invalid configuration `current_user_method`, expected a symbol or a string, got #{value.inspect}"
              ).process
            end
    setting :user_model_name,
            default: "User",
            reader: true,
            constructor: -> (value) do
              Rabarber::Inputs::NonEmptyString.new(
                value,
                error: Rabarber::ConfigurationError,
                message: "Invalid configuration `user_model_name`, expected an ActiveRecord model name, got #{value.inspect}"
              ).process
            end

    def user_model
      Rabarber::Inputs::Model.new(
        user_model_name,
        error: Rabarber::ConfigurationError,
        message: "Invalid configuration `user_model_name`, expected an ActiveRecord model name, got #{user_model_name.inspect}"
      ).process
    end
  end
end
