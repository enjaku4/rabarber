# frozen_string_literal: true

module Rabarber
  module Core
    module Roleable
      def roleable
        current_user = send(Rabarber::Configuration.instance.current_user_method)

        unless current_user.is_a?(Rabarber::Configuration.instance.user_model)
          raise(
            Rabarber::Error,
            "Expected an instance of #{Rabarber::Configuration.instance.user_model.name} from #{Rabarber::Configuration.instance.current_user_method.inspect} method, but got #{current_user.inspect}"
          )
        end

        current_user
      end

      def roleable_roles(context: nil)
        roleable.roles(context:)
      end
    end
  end
end
