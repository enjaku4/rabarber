# frozen_string_literal: true

module Rabarber
  module Helpers
    include Rabarber::Core::Roleable

    def visible_to(*roles, &block)
      return unless roleable_roles.intersection(Rabarber::Input::Roles.new(roles).process).any?

      capture(&block)
    end

    def hidden_from(*roles, &block)
      return if roleable_roles.intersection(Rabarber::Input::Roles.new(roles).process).any?

      capture(&block)
    end
  end
end
