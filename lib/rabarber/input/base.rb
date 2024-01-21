# frozen_string_literal: true

module Rabarber
  module Input
    class Base
      attr_reader :value, :error_type, :error_message

      def initialize(value, error_type, error_message)
        @value = value
        @error_type = error_type
        @error_message = error_message
      end

      def process
        valid? ? processed_value : raise_error
      end

      private

      def valid?
        raise NotImplementedError
      end

      def processed_value
        raise NotImplementedError
      end

      def raise_error
        raise error_type, error_message
      end
    end
  end
end
