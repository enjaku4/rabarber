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

      return if Rabarber::Core::Permissions.access_granted?(rabarber_roles, self.class, action_name.to_sym, self)

      Rabarber::Logger.audit(:warn, rabarber_unauthorized_attempt_log_message)
      Rabarber::Configuration.instance.when_unauthorized.call(self)
    end

    def rabarber_roles
      user = send(Rabarber::Configuration.instance.current_user_method)
      user ? user.roles : []
    end

    # TODO: this should be somewhere else
    def rabarber_unauthorized_attempt_log_message
      user = send(Rabarber::Configuration.instance.current_user_method)

      user_identity = if user
                        model_name = user.model_name.human
                        primary_key = user.class.primary_key
                        user_id = user.public_send(user.class.primary_key)
                        roles = user.roles

                        "#{model_name} with #{primary_key}: '#{user_id}', roles: #{roles}"
                      else
                        "Unauthenticated user"
                      end

      "[Unauthorized Attempt] #{user_identity} attempted to access '#{request.path}'"
    end
  end
end
