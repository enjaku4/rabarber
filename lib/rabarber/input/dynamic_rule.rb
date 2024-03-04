# frozen_string_literal: true

module Rabarber
  module Input
    class DynamicRule < Rabarber::Input::Base
      def initialize(
        value,
        error_type = Rabarber::InvalidArgumentError,
        error_message = "Dynamic rule must be a Symbol, a String, or a Proc"
      )
        super
      end

      def valid?
        Rabarber::Input::Types::Symbol.new(value, nil, nil).valid? ||
          Rabarber::Input::Types::Proc.new(value, nil, nil).valid? ||
          value.nil?
      end

      private

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
