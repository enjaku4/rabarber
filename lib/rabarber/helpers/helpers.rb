# frozen_string_literal: true

module Rabarber
  module Helpers
    def visible_to(*roles, &)
      return unless send(Rabarber::Configuration.instance.current_user_method).has_role?(*roles)

      capture(&)
    end

    def hidden_from(*roles, &)
      return if send(Rabarber::Configuration.instance.current_user_method).has_role?(*roles)

      capture(&)
    end
  end
end
