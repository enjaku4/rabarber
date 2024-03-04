# frozen_string_literal: true

module Rabarber
  module Input
    class Action < Rabarber::Input::Base
      def initialize(
        value,
        error_type = Rabarber::InvalidArgumentError,
        error_message = "Action name must be a Symbol or a String"
      )
        super
      end

      def valid?
        Rabarber::Input::Types::Symbol.new(value, nil, nil).valid? || value.nil?
      end

      private

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
