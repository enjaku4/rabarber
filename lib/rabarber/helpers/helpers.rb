# frozen_string_literal: true

module Rabarber
  module Helpers
    include Rabarber::Core::Roleable

    def visible_to(*roles, context: nil, &block)
      capture(&block) if roleable.has_role?(*roles, context: context)
    end

    def hidden_from(*roles, context: nil, &block)
      capture(&block) unless roleable.has_role?(*roles, context: context)
    end
  end
end
