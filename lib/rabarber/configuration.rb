# frozen_string_literal: true

require "singleton"

module Rabarber
  class Configuration
    include Singleton

    attr_reader :audit_trail_enabled, :cache_enabled, :current_user_method, :must_have_roles

    def initialize
      @audit_trail_enabled = true
      @cache_enabled = true
      @current_user_method = :current_user
      @must_have_roles = false
    end

    [:audit_trail_enabled, :cache_enabled, :must_have_roles].each do |method_name|
      define_method(:"#{method_name}=") do |value|
        instance_variable_set(:"@#{method_name}", Rabarber::Input::Types::Boolean.new(
          value, Rabarber::ConfigurationError, "Configuration '#{method_name}' must be a Boolean"
        ).process)
      end
    end

    def current_user_method=(method_name)
      @current_user_method = Rabarber::Input::Types::Symbol.new(
        method_name, Rabarber::ConfigurationError, "Configuration 'current_user_method' must be a Symbol or a String"
      ).process
    end
  end
end
