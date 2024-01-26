# frozen_string_literal: true

module Rabarber
  module Input
    class Roles < Base
      REGEX = /\A[a-z0-9_]+\z/

      def initialize(
        value,
        error_type = ::Rabarber::InvalidArgumentError,
        error_message =
          "Role names must be Symbols or Strings and may only contain lowercase letters, numbers and underscores"
      )
        super
      end

      def value
        Array(super)
      end

      private

      def valid?
        value.all? { |role_name| (role_name.is_a?(Symbol) || role_name.is_a?(String)) && role_name.to_s.match?(REGEX) }
      end

      def processed_value
        value.map(&:to_sym)
      end
    end
  end
end
