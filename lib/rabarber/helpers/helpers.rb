# frozen_string_literal: true

module Rabarber
  module Helpers
    include Rabarber::Core::Roleable

    def visible_to(*roles, context: nil, &)
      capture(&) if roleable.has_role?(*roles, context:)
    end

    def hidden_from(*roles, context: nil, &)
      capture(&) unless roleable.has_role?(*roles, context:)
    end
  end
end
