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

        Permissions.add(
          self,
          Input::Actions.new(action).process,
          Input::Roles.new(roles).process,
          Input::DynamicRules.new(dynamic_rule).process,
          Input::DynamicRules.new(negated_dynamic_rule).process
        )
      end
    end

    private

    def verify_access
      return if Permissions.access_granted?(
        send(::Rabarber::Configuration.instance.current_user_method).roles, self.class, action_name.to_sym, self
      )

      ::Rabarber::Configuration.instance.when_unauthorized.call(self)
    end
  end
end
