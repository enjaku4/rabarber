# frozen_string_literal: true

module Rabarber
  module Authorization
    extend ActiveSupport::Concern
    include Rabarber::Core::Roleable

    class_methods do
      def skip_authorization(options = {})
        skip_before_action :authorize, **options
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

    def authorize
      return if Rabarber::Core::Permissions.access_granted?(roleable, action_name.to_sym, self)

      when_unauthorized
    end

    def when_unauthorized
      request.format.html? ? redirect_back(fallback_location: root_path) : head(:unauthorized)
    end
  end
end
