# frozen_string_literal: true

module Rabarber
  module Core
    module Roleable
      def roleable
        send(Rabarber::Configuration.instance.current_user_method) || NullRoleable.new
      end

      def roleable_roles(context: nil)
        roleable.roles(context: context)
      end
    end

    class NullRoleable
      def roles(context:) # rubocop:disable Lint/UnusedMethodArgument
        []
      end

      def log_identity
        "Unauthenticated #{Rabarber::HasRoles.roleable_class.model_name.human.downcase}"
      end
    end
  end
end
