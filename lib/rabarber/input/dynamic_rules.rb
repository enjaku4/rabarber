# frozen_string_literal: true

module Rabarber
  module Input
    class DynamicRules < Base
      def initialize(
        value,
        error_type = InvalidArgumentError,
        error_message = "Dynamic rule must be a Symbol, a String, or a Proc"
      )
        super
      end

      private

      def valid?
        (value.is_a?(String) || value.is_a?(Symbol)) && value.present? || value.nil? || value.is_a?(Proc)
      end

      def processed_value
        case value
        when String, Symbol
          value.to_sym
        when Proc, nil
          value
        end
      end
    end
  end
end