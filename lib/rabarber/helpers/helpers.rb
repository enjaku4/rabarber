# frozen_string_literal: true

module Rabarber
  module Helpers
    def visible_to(*roles, &block)
      return unless send(Rabarber::Configuration.instance.current_user_method).has_role?(*roles)

      capture(&block)
    end

    def hidden_from(*roles, &block)
      return if send(Rabarber::Configuration.instance.current_user_method).has_role?(*roles)

      capture(&block)
    end
  end
end
