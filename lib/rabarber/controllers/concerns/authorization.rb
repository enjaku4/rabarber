# frozen_string_literal: true

module Rabarber
  module Authorization
    extend ActiveSupport::Concern

    include Rabarber::Core::Roleable

    included do
      before_action :verify_access
    end

    class_methods do
      def grant_access(action: nil, roles: nil, if: nil, unless: nil)
        # TODO: this must accept context argument which is nil by default, but can also be a class or an instance
        # TODO: the context stored in memory must be represented as a hash { class_name: ..., id: ... }
        # TODO: both values in the hash can be nil
        # TODO: when access permissions are checked, the roles must be checked for the context
        # TODO: class_name.nil? && id.nil? means checking for global roles
        # TODO: class_name.nil? && !id.nil? means checking for class roles (e.g. a user can be an admin of every Project)
        # TODO: !class_name.nil? && !id.nil? means checking for instance roles
        # TODO: default nil context should provide a seamless upgrade as previous versions supported only global roles
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
      Rabarber::Core::PermissionsIntegrityChecker.new(self.class).run! unless Rails.configuration.eager_load

      return if Rabarber::Core::Permissions.access_granted?(roleable_roles, self.class, action_name.to_sym, self)

      Rabarber::Audit::Events::UnauthorizedAttempt.trigger(roleable, path: request.path)

      when_unauthorized
    end

    def when_unauthorized
      request.format.html? ? redirect_back(fallback_location: root_path) : head(:unauthorized)
    end
  end
end
