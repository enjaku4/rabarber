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
          Rabarber::Input::Action.new(action).process,
          Rabarber::Input::Roles.new(roles).process,
          Rabarber::Input::AuthorizationContext.new(context).process,
          Rabarber::Input::DynamicRule.new(binding.local_variable_get(:if)).process,
          Rabarber::Input::DynamicRule.new(binding.local_variable_get(:unless)).process
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
