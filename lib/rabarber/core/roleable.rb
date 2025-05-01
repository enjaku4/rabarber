# frozen_string_literal: true

module Rabarber
  module Core
    module Roleable
      def roleable
        current_roleable = send(Rabarber::Configuration.instance.current_user_method)

        unless current_roleable.is_a?(Rabarber::Configuration.instance.user_model)
          raise(
            Rabarber::Error,
            "Expected an instance of #{Rabarber::Configuration.instance.user_model.name} from #{Rabarber::Configuration.instance.current_user_method} method, but got #{current_roleable.inspect}"
          )
        end

        current_roleable
      end

      def roleable_roles(context: nil)
        roleable.roles(context:)
      end
    end
  end
end
