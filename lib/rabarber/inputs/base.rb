# frozen_string_literal: true

require "dry-types"

module Rabarber
  module Inputs
    class Base
      include Dry.Types()

      def initialize(value, optional: false, error: Rabarber::InvalidArgumentError, message: nil)
        @value = value
        @optional = optional
        @error = error
        @message = message
      end

      def process
        type_checker = @optional ? type.optional : type
        type_checker[@value]
      rescue Dry::Types::CoercionError
        raise_error
      end

      private

      def type
        raise NotImplementedError
      end

      def raise_error
        raise @error, @message
      end
    end
  end
end
