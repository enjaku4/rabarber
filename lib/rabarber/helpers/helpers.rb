# frozen_string_literal: true

module Rabarber
  module Helpers
    include Rabarber::Core::Roleable

    def visible_to(*roles, context: nil, &block)
      capture(&block) if roles_match?(roles, context)
    end

    def hidden_from(*roles, context: nil, &block)
      capture(&block) unless roles_match?(roles, context)
    end

    private

    def roles_match?(roles, context)
      processed_roles = Rabarber::Input::Roles.new(roles).process
      processed_context = Rabarber::Input::Context.new(context).process
      roleable_roles(context: processed_context).any? { |role| processed_roles.include?(role) }
    end
  end
end
