# frozen_string_literal: true

module Rabarber
  module Core
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
