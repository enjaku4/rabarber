# frozen_string_literal: true

module Rabarber
  module Inputs
    class Base
      def initialize(value, optional: false, error: Rabarber::InvalidArgumentError, message: nil)
        @value = value
        @optional = optional
        @error = error
        @message = message
      end

      def process
        return @value if @value.nil? && @optional

        validate_and_normalize
      end

      private

      def validate_and_normalize
        raise NotImplementedError
      end

      def raise_error
        raise @error, @message
      end
    end
  end
end
