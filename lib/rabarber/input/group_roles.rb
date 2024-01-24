# frozen_string_literal: true

module Rabarber
  module Input
    class GroupRoles < Base
      def initialize(
        value,
        error_type = InvalidArgumentError,
        error_message =
          "Role group name must be a Symbol or String and may only contain lowercase letters, numbers and underscores"
      )
        super
      end

      private

      def valid?
        (value.is_a?(Symbol) || value.is_a?(String)) && value.to_s.match?(Input::Roles::REGEX) || value.nil?
      end

      def processed_value
        Array(Rabarber::Group.find_by(name: value)&.roles)
      end
    end
  end
end
