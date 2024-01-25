# frozen_string_literal: true

module Rabarber
  module Input
    class Actions < Base
      def initialize(
        value,
        error_type = InvalidArgumentError,
        error_message = "Action name must be a Symbol or a String"
      )
        super
      end

      private

      def valid?
        (value.is_a?(String) || value.is_a?(Symbol)) && value.present? || value.nil?
      end

      def processed_value
        case value
        when String, Symbol
          value.to_sym
        when nil
          value
        end
      end
    end
  end
end
