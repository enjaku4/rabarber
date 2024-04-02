# frozen_string_literal: true

module Rabarber
  module Helpers
    def visible_to(*roles, &block)
      roleable = send(Rabarber::Configuration.instance.current_user_method)
      rabarber_roles = roleable ? roleable.roles : []

      return unless rabarber_roles.intersection(Rabarber::Input::Roles.new(roles).process).any?

      capture(&block)
    end

    def hidden_from(*roles, &block)
      roleable = send(Rabarber::Configuration.instance.current_user_method)
      rabarber_roles = roleable ? roleable.roles : []

      return if rabarber_roles.intersection(Rabarber::Input::Roles.new(roles).process).any?

      capture(&block)
    end
  end
end
