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

        Rabarber::Permissions.add(
          self,
          Rabarber::Input::Actions.new(action).process,
          Rabarber::Input::Roles.new(roles).process,
          Rabarber::Input::DynamicRules.new(dynamic_rule).process,
          Rabarber::Input::DynamicRules.new(negated_dynamic_rule).process
        )
      end
    end

    private

    def verify_access
      Rabarber::Missing::Actions.new(self.class).handle
      Rabarber::Missing::Roles.new(self.class).handle

      return if Rabarber::Permissions.access_granted?(rabarber_roles, self.class, action_name.to_sym, self)

      Rabarber::Configuration.instance.when_unauthorized.call(self)
    end

    def rabarber_roles
      user = send(Rabarber::Configuration.instance.current_user_method)

      if user
        Rabarber::Cache.fetch(Rabarber::Cache.key_for(user), expires_in: 1.hour, race_condition_ttl: 5.seconds) do
          user.roles
        end
      else
        []
      end
    end
  end
end
