# frozen_string_literal: true

module Rabarber
  module Input
    class Roles < Rabarber::Input::Base
      def initialize(
        value,
        error_type = Rabarber::InvalidArgumentError,
        error_message =
          "Role names must be Symbols or Strings and may only contain lowercase letters, numbers and underscores"
      )
        super
      end

      def value
        Array(super)
      end

      def valid?
        value.all? { |role_name| Rabarber::Input::Role.new(role_name).valid? }
      end

      private

      def processed_value
        value.map(&:to_sym)
      end
    end
  end
end
