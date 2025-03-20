# frozen_string_literal: true

module Rabarber
  module Core
    class NullRoleable
      def roles(context:) # rubocop:disable Lint/UnusedMethodArgument
        []
      end

      def all_roles
        {}
      end

      def has_role?(*role_names, context: nil) # rubocop:disable Lint/UnusedMethodArgument
        false
      end

      def log_identity
        "Unauthenticated #{Rabarber::HasRoles.roleable_class.model_name.human.downcase}"
      end
    end
  end
end
