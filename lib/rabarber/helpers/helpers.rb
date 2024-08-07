# frozen_string_literal: true

module Rabarber
  module Helpers
    include Rabarber::Core::Roleable

    def visible_to(*roles, context: nil, &block)
      return if roleable_roles(context: Rabarber::Input::Context.new(context).process).intersection(Rabarber::Input::Roles.new(roles).process).none?

      capture(&block)
    end

    def hidden_from(*roles, context: nil, &block)
      return if roleable_roles(context: Rabarber::Input::Context.new(context).process).intersection(Rabarber::Input::Roles.new(roles).process).any?

      capture(&block)
    end
  end
end
