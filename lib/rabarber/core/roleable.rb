# frozen_string_literal: true

module Rabarber
  module Core
    module Roleable
      def roleable
        send(Rabarber::Configuration.instance.current_user_method)
      end

      def roleable_roles(context: nil)
        roleable&.roles(context: context) || []
      end
    end
  end
end
