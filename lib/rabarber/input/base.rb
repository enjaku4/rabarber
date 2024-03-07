# frozen_string_literal: true

module Rabarber
  module Input
    class Base
      attr_reader :value, :error_type, :error_message

      def initialize(value, error_type = Rabarber::InvalidArgumentError, error_message = default_error_message)
        @value = value
        @error_type = error_type
        @error_message = error_message
      end

      def process
        valid? ? processed_value : raise_error
      end

      def valid?
        raise NotImplementedError
      end

      private

      def processed_value
        raise NotImplementedError
      end

      def default_error_message
        raise NotImplementedError
      end

      def raise_error
        raise error_type, error_message
      end
    end
  end
end
