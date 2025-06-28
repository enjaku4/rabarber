# frozen_string_literal: true

module Rabarber
  module Input
    class DynamicRule < Rabarber::Input::Base
      def valid?
        Rabarber::Input::Types::Symbol.new(value).valid? || Rabarber::Input::Types::Proc.new(value).valid? || value.nil?
      end

      private

      def processed_value
        value.is_a?(String) ? value.to_sym : value
      end

      def default_error_message
        "Expected a symbol, a string, or a proc, got #{value.inspect}"
      end
    end
  end
end
