# frozen_string_literal: true

module Rabarber
  module Input
    class Role < Rabarber::Input::Base
      REGEX = /\A[a-z0-9_]+\z/

      def initialize(
        value,
        error_type = Rabarber::InvalidArgumentError,
        error_message =
          "Role name must be a Symbol or a String and may only contain lowercase letters, numbers and underscores"
      )
        super
      end

      def valid?
        Rabarber::Input::Types::Symbol.new(value, nil, nil).valid? && value.to_s.match?(REGEX)
      end

      private

      def processed_value
        value.to_sym
      end
    end
  end
end
