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
        raise @error, @message
      end

      private

      def type
        raise NotImplementedError
      end
    end
  end
end
