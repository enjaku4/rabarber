# frozen_string_literal: true

module Rabarber
  module Authorization
    extend ActiveSupport::Concern

    included do
      before_action :check_permissions
    end

    class_methods do
      def grant_access(action: nil, roles: nil, if: nil)
        Permissions.write(self, action, roles, binding.local_variable_get(:if))
      end
    end

    private

    def check_permissions
      return if Permissions.access_granted?(
        send(::Rabarber::Configuration.instance.current_user_method).roles.names, self.class, action_name.to_sym, self
      )

      ::Rabarber::Configuration.instance.when_unauthorized.call(self)
    end
  end
end
