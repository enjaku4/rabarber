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
        Rabarber::Core::Permissions.add(
          self,
          Rabarber::Inputs.process(
            action,
            as: :symbol,
            optional: true,
            message: "Expected a symbol or a string, got #{action.inspect}"
          ),
          Rabarber::Inputs.process(
            roles,
            as: :roles,
            message: "Expected an array of symbols or strings containing only lowercase letters, numbers, and underscores, got #{roles.inspect}"
          ),
          Rabarber::Inputs.process(
            context,
            as: :authorization_context,
            message: "Expected a Class, an instance of ActiveRecord model, a symbol, a string, or a proc, got #{context.inspect}"
          ),
          Rabarber::Inputs.process(
            binding.local_variable_get(:if),
            as: :dynamic_rule,
            optional: true,
            message: "Expected a symbol, a string, or a proc, got #{binding.local_variable_get(:if).inspect}"
          ),
          Rabarber::Inputs.process(
            binding.local_variable_get(:unless),
            as: :dynamic_rule,
            optional: true,
            message: "Expected a symbol, a string, or a proc, got #{binding.local_variable_get(:unless).inspect}"
          )
        )
      end
    end

    private

    def with_authorization
      return if Rabarber::Core::Permissions.access_granted?(roleable, action_name.to_sym, self)

      when_unauthorized
    end

    def when_unauthorized
      request.format.html? ? redirect_back(fallback_location: root_path) : head(:forbidden)
    end
  end
end
