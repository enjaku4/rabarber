# frozen_string_literal: true

require_relative "null_roleable"

module Rabarber
  module Core
    module Roleable
      def roleable
        send(Rabarber::Configuration.instance.current_user_method) || NullRoleable.new
      end

      def roleable_roles(context: nil)
        roleable.roles(context:)
      end
    end
  end
end
