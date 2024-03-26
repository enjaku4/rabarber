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
      Rabarber::Missing::Actions.new(self.class).handle unless Rails.configuration.eager_load
      Rabarber::Missing::Roles.new(self.class).handle if Rabarber::Role.table_exists?

      roleable = send(Rabarber::Configuration.instance.current_user_method)

      return if Rabarber::Core::Permissions.access_granted?(
        roleable ? roleable.roles : [], self.class, action_name.to_sym, self
      )

      Rabarber::Logger.audit(
        :warn,
        "[Unauthorized Attempt] #{Rabarber::Logger.roleable_identity(roleable, with_roles: true)} attempted to access '#{request.path}'"
      )

      when_unauthorized
    end

    def when_unauthorized
      request.format.html? ? redirect_back(fallback_location: root_path) : head(:unauthorized)
    end
  end
end
