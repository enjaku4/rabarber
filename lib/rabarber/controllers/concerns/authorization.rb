# frozen_string_literal: true

module Rabarber
  module Authorization
    extend ActiveSupport::Concern
    include Rabarber::Core::Roleable

    class_methods do
      def with_authorization(options = {})
        before_action :with_authorization, **options
      rescue ArgumentError => e
        raise Rabarber::InvalidArgumentError, e.message
      end

      def skip_authorization(options = {})
        skip_before_action :with_authorization, **options
      rescue ArgumentError => e
        raise Rabarber::InvalidArgumentError, e.message
      end

      def grant_access(action: nil, roles: nil, context: nil, if: nil, unless: nil)
        if_rule = binding.local_variable_get(:if)
        unless_rule = binding.local_variable_get(:unless)

        Rabarber::Core::Permissions.add(
          self,
          Rabarber::Inputs::Symbol.new(
            action,
            optional: true,
            message: "Expected a symbol or a string, got #{action.inspect}"
          ).process,
          Rabarber::Inputs::Roles.new(
            roles,
            message: "Expected an array of symbols or strings containing only lowercase letters, numbers, and underscores, got #{roles.inspect}"
          ).process,
          Rabarber::Inputs::Contexts::Authorizational.new(
            context,
            error: Rabarber::InvalidContextError,
            message: "Expected a Class, an instance of ActiveRecord model, a symbol, a string, or a proc, got #{context.inspect}"
          ).resolve,
          Rabarber::Inputs::DynamicRule.new(
            if_rule,
            optional: true,
            message: "Expected a symbol, a string, or a proc, got #{if_rule.inspect}"
          ).process,
          Rabarber::Inputs::DynamicRule.new(
            unless_rule,
            optional: true,
            message: "Expected a symbol, a string, or a proc, got #{unless_rule.inspect}"
          ).process
        )
      end
    end

    private

    def with_authorization
      return if Rabarber::Core::Permissions.access_granted?(roleable, action_name.to_sym, self)

      when_unauthorized
    end

    def when_unauthorized
      request.format.html? ? redirect_back_or_to(root_path) : head(:forbidden)
    end
  end
end
