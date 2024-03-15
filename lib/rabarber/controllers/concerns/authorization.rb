# frozen_string_literal: true

module Rabarber
  module Authorization
    extend ActiveSupport::Concern

    included do
      before_action :verify_access
    end

    class_methods do
      def grant_access(action: nil, roles: nil, if: nil, unless: nil)
        dynamic_rule, negated_dynamic_rule = binding.local_variable_get(:if), binding.local_variable_get(:unless)

        Rabarber::Core::Permissions.add(
          self,
          Rabarber::Input::Action.new(action).process,
          Rabarber::Input::Roles.new(roles).process,
          Rabarber::Input::DynamicRule.new(dynamic_rule).process,
          Rabarber::Input::DynamicRule.new(negated_dynamic_rule).process
        )
      end
    end

    private

    def verify_access
      Rabarber::Missing::Actions.new(self.class).handle
      Rabarber::Missing::Roles.new(self.class).handle

      roleable = send(Rabarber::Configuration.instance.current_user_method)

      return if Rabarber::Core::Permissions.access_granted?(
        roleable ? roleable.roles : [], self.class, action_name.to_sym, self
      )

      Rabarber::Logger.audit(
        :warn,
        "[Unauthorized Attempt] #{Rabarber::Logger.roleable_identity(roleable, with_roles: true)} attempted to access '#{request.path}'"
      )

      Rabarber::Configuration.instance.when_unauthorized.call(self)
    end
  end
end
