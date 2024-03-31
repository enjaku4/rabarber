# frozen_string_literal: true

module Rabarber
  module Helpers
    def visible_to(*roles, &)
      roleable = send(Rabarber::Configuration.instance.current_user_method)
      rabarber_roles = roleable ? roleable.roles : []

      return unless rabarber_roles.intersect?(Rabarber::Input::Roles.new(roles).process)

      capture(&)
    end

    def hidden_from(*roles, &)
      roleable = send(Rabarber::Configuration.instance.current_user_method)
      rabarber_roles = roleable ? roleable.roles : []

      return if rabarber_roles.intersect?(Rabarber::Input::Roles.new(roles).process)

      capture(&)
    end
  end
end
