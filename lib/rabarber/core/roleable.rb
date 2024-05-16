# frozen_string_literal: true

module Rabarber
  module Core
    module Roleable
      def roleable
        # TODO: how about NullRoleable
        send(Rabarber::Configuration.instance.current_user_method)
      end

      def roleable_roles
        # TODO: this will work, but the roles are no longer cached
        roleable ? roleable.rabarber_roles : Rabarber::Role.none
      end
    end
  end
end
